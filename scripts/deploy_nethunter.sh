#!/usr/bin/env bash
# deploy_nethunter.sh - Kali NetHunter Chroot & KeX Deployer for Fire HD 10 (suez)
#
# Automates:
#   1. Termux installation
#   2. NetHunter ARMHF rootfs extraction into /data/local/nhsystem/kali-armhf
#   3. Deployment of /system/bin/bootkali and /system/bin/kex
#   4. TigerVNC and XFCE4 desktop configuration (KeX)
#   5. Setting up Termux shortcuts (nh, kali, kex)
#   6. Verification of chroot and toolchain
#
# Usage:
#   ./deploy_nethunter.sh <kali-rootfs.tar.xz> [termux.apk]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS_ARCHIVE="${1:-}"
TERMUX_APK="${2:-}"

if [ -z "$ROOTFS_ARCHIVE" ] || [ ! -f "$ROOTFS_ARCHIVE" ]; then
    echo "[-] Error: Please specify the Kali NetHunter rootfs archive (tar.xz)."
    echo "Usage: $0 <kali-nethunter-rootfs-full-armhf.tar.xz> [termux.apk]"
    exit 1
fi

echo "[*] Connecting to Android device via ADB..."
adb wait-for-device

# Verify root access
echo "[*] Checking root privileges..."
ROOT_CHECK=$(adb shell "su -c 'id -u'" 2>/dev/null | tr -d '\r' || echo "failed")
if [ "$ROOT_CHECK" != "0" ]; then
    echo "[-] Error: Root access via Magisk is required. Please grant root permissions to ADB shell."
    exit 1
fi
echo "[+] Root verified (uid 0)."

# 1. Install Termux if provided
if [ -n "$TERMUX_APK" ] && [ -f "$TERMUX_APK" ]; then
    echo "[*] Installing Termux APK ($TERMUX_APK)..."
    adb install -r "$TERMUX_APK"
    echo "[+] Termux installed."
fi

# 2. Extract Kali Rootfs
CHROOT_PATH="/data/local/nhsystem/kali-armhf"
echo "[*] Target chroot path: $CHROOT_PATH"

adb shell "su -c 'mkdir -p $CHROOT_PATH'"

echo "[*] Streaming and extracting Kali rootfs to device..."
echo "[*] (This can take 5-10 minutes depending on USB speed, please wait...)"
cat "$ROOTFS_ARCHIVE" | adb shell "su -c 'tar -xJf - -C $CHROOT_PATH'"
echo "[+] Kali NetHunter rootfs successfully unpacked."

# 3. Deploy bootkali wrapper to /system/bin/bootkali
echo "[*] Installing /system/bin/bootkali..."
adb shell "su -c 'mount -o remount,rw /system'"
adb push "$SCRIPT_DIR/bootkali" /data/local/tmp/bootkali
adb shell "su -c 'cp /data/local/tmp/bootkali /system/bin/bootkali && chmod 755 /system/bin/bootkali && rm /data/local/tmp/bootkali'"

# 4. Deploy kex script inside chroot and system
echo "[*] Installing kex launcher..."
adb push "$SCRIPT_DIR/kex" /data/local/tmp/kex
adb shell "su -c 'cp /data/local/tmp/kex $CHROOT_PATH/usr/bin/kex && chmod 755 $CHROOT_PATH/usr/bin/kex'"
adb shell "su -c 'cat << \"EOF\" > /system/bin/kex
#!/system/bin/sh
/system/bin/bootkali /usr/bin/kex \"\$@\"
EOF
chmod 755 /system/bin/kex'"

# 5. Configure TigerVNC / XFCE4 KeX
echo "[*] Configuring KeX desktop environment..."
adb shell "su -c '/system/bin/bootkali mkdir -p /root/.config/tigervnc'"
adb push "$SCRIPT_DIR/../configs/xstartup" /data/local/tmp/xstartup
adb shell "su -c 'cp /data/local/tmp/xstartup $CHROOT_PATH/root/.config/tigervnc/xstartup && chmod 755 $CHROOT_PATH/root/.config/tigervnc/xstartup && rm /data/local/tmp/xstartup'"
adb shell "su -c '/system/bin/bootkali ln -sf /root/.config/tigervnc /root/.vnc'"

# Set default KeX password to 'kali' (can be changed later via 'kex passwd')
echo "[*] Setting default KeX password ('kali')..."
adb shell "su -c '/system/bin/bootkali bash -c \"echo kali | vncpasswd -f > /root/.config/tigervnc/passwd && chmod 600 /root/.config/tigervnc/passwd\"'"

# 6. Configure Termux shortcuts if Termux data dir exists
echo "[*] Configuring Termux aliases..."
adb shell "su -c 'if [ -d /data/data/com.termux/files/home ]; then
    cat << \"EOF\" > /data/data/com.termux/files/home/.bashrc
echo \"=== Kali NetHunter (Fire HD 10) ===\"
echo \"  Type \\\"nh\\\" or \\\"kali\\\" to enter Kali Linux chroot\"
echo \"  Type \\\"kex start\\\" to launch KeX Remote Desktop\"
alias nh=\"su -c /system/bin/bootkali\"
alias kali=\"su -c /system/bin/bootkali\"
alias kex=\"su -c /system/bin/kex\"
EOF
    chown -R \$(stat -c %u:%g /data/data/com.termux/files/home) /data/data/com.termux/files/home/.bashrc
fi'"

# 7. Verification
echo "[*] Verifying installation..."
CHROOT_TEST=$(adb shell "su -c '/system/bin/bootkali nmap --version 2>&1 | head -n 1'" 2>/dev/null | tr -d '\r' || echo "failed")
echo "[+] Verification output: $CHROOT_TEST"

echo ""
echo "========================================================"
echo "[+] Kali NetHunter deployment complete!"
echo "    - Terminal Chroot:  su -c /system/bin/bootkali"
echo "    - KeX GUI Desktop:  su -c /system/bin/kex start"
echo "    - KeX VNC Port:     5901 (Default password: kali)"
echo "========================================================"
