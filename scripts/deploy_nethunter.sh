#!/usr/bin/env bash
# deploy_nethunter.sh - Full Official Kali NetHunter Suite Deployer for Fire HD 10 (suez)
#
# Automates:
#   1. NetHunter ARMHF rootfs extraction into /data/local/nhsystem/kali-armhf
#   2. Installation of the Official NetHunter Application Suite:
#        - NetHunter App (com.offsec.nethunter)
#        - NetHunter Terminal (com.offsec.nhterm)
#        - NetHunter KeX (com.offsec.nethunter.kex)
#        - NetHunter Store (com.offsec.nethunter.store)
#   3. Automated configuration of NetHunter App preferences & Chroot Manager hook
#   4. Deployment of /system/bin/bootkali and /system/bin/kex
#   5. TigerVNC and XFCE4 desktop configuration (KeX 1920x1200)
#   6. Verification of chroot and toolchain
#
# Usage:
#   ./deploy_nethunter.sh <kali-rootfs.tar.xz> [path-to-apks-folder-or-apk]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS_ARCHIVE="${1:-}"
APK_TARGET="${2:-}"

if [ -z "$ROOTFS_ARCHIVE" ] || [ ! -f "$ROOTFS_ARCHIVE" ]; then
    echo "[-] Error: Please specify the Kali NetHunter rootfs archive (tar.xz)."
    echo "Usage: $0 <kali-nethunter-rootfs-full-armhf.tar.xz> [apk-directory-or-file]"
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

# 1. Install NetHunter Applications
if [ -n "$APK_TARGET" ]; then
    if [ -d "$APK_TARGET" ]; then
        echo "[*] Installing NetHunter APKs from directory: $APK_TARGET..."
        for apk in "$APK_TARGET"/*.apk; do
            [ -e "$apk" ] || continue
            echo "    -> Installing $(basename "$apk")..."
            adb install -r -g "$apk" || true
        done
    elif [ -f "$APK_TARGET" ]; then
        echo "[*] Installing APK: $APK_TARGET..."
        adb install -r -g "$APK_TARGET" || true
    fi
else
    echo "[*] No APK path provided. Checking if NetHunter app is already installed..."
    if ! adb shell pm list packages | grep -q "com.offsec.nethunter"; then
        echo "[*] NetHunter App not found. Downloading NetHunterStore.apk..."
        curl -sSL "https://store.nethunter.com/NetHunterStore.apk" -o "/tmp/NetHunterStore.apk"
        adb install -r -g "/tmp/NetHunterStore.apk"
        echo "[+] Installed NetHunter Store. Please install NetHunter, Terminal, and KeX via the Store."
    fi
fi

# 2. Extract Kali Rootfs
CHROOT_PATH="/data/local/nhsystem/kali-armhf"
echo "[*] Target chroot path: $CHROOT_PATH"

adb shell "su -c 'mkdir -p $CHROOT_PATH'"

echo "[*] Streaming and extracting Kali rootfs to device..."
echo "[*] (This can take 5-10 minutes depending on USB speed, please wait...)"
cat "$ROOTFS_ARCHIVE" | adb shell "su -c 'tar -xJf - -C $CHROOT_PATH'"
echo "[+] Kali NetHunter rootfs successfully unpacked."

# 3. Configure NetHunter App Preferences (Chroot Hook)
echo "[*] Configuring NetHunter App Chroot Manager preferences..."
adb shell "su -c 'mkdir -p /data/data/com.offsec.nethunter/shared_prefs'"
adb shell "su -c 'cat << \"EOF\" > /data/data/com.offsec.nethunter/shared_prefs/com.offsec.nethunter.xml
<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\" ?>
<map>
    <string name=\"chroot_arch\">kali-armhf</string>
    <boolean name=\"CHROOT_INSTALLED_TAG\" value=\"true\" />
    <boolean name=\"set_setup_done\" value=\"true\" />
    <string name=\"chroot_path\">/data/local/nhsystem/kali-armhf</string>
    <boolean name=\"files_copied\" value=\"true\" />
    <boolean name=\"seenNav\" value=\"true\" />
</map>
EOF
if [ -d /data/data/com.offsec.nethunter ]; then
    chown -R \$(stat -c %u:%g /data/data/com.offsec.nethunter) /data/data/com.offsec.nethunter/shared_prefs
    chmod 660 /data/data/com.offsec.nethunter/shared_prefs/com.offsec.nethunter.xml
fi'"

# 4. Deploy bootkali and kex wrappers
echo "[*] Installing /system/bin/bootkali and /system/bin/kex..."
adb shell "su -c 'mount -o remount,rw /system'"

# Install fallback bootkali script
adb push "$SCRIPT_DIR/bootkali" /data/local/tmp/bootkali
adb shell "su -c 'if [ ! -L /system/bin/bootkali ]; then cp /data/local/tmp/bootkali /system/bin/bootkali && chmod 755 /system/bin/bootkali; fi && rm /data/local/tmp/bootkali'"

# Install kex launcher
adb push "$SCRIPT_DIR/kex" /data/local/tmp/kex
adb shell "su -c 'cp /data/local/tmp/kex $CHROOT_PATH/usr/bin/kex && chmod 755 $CHROOT_PATH/usr/bin/kex'"
adb shell "su -c 'cat << \"EOF\" > /system/bin/kex
#!/system/bin/sh
if [ -x /data/data/com.offsec.nethunter/scripts/bin/busybox_nh ]; then
    /data/data/com.offsec.nethunter/scripts/bin/busybox_nh chroot /data/local/nhsystem/kali-armhf /usr/bin/kex \"\$@\"
else
    /system/bin/chroot /data/local/nhsystem/kali-armhf /usr/bin/kex \"\$@\"
fi
EOF
chmod 755 /system/bin/kex'"

# 5. Configure TigerVNC / XFCE4 KeX
echo "[*] Configuring KeX desktop environment..."
adb shell "su -c 'mkdir -p $CHROOT_PATH/root/.config/tigervnc'"
adb push "$SCRIPT_DIR/../configs/xstartup" /data/local/tmp/xstartup
adb shell "su -c 'cp /data/local/tmp/xstartup $CHROOT_PATH/root/.config/tigervnc/xstartup && chmod 755 $CHROOT_PATH/root/.config/tigervnc/xstartup && rm /data/local/tmp/xstartup'"
adb shell "su -c 'ln -sf $CHROOT_PATH/root/.config/tigervnc $CHROOT_PATH/root/.vnc'"

# Set default KeX password to 'kali' (can be changed later via 'kex passwd')
echo "[*] Setting default KeX password ('kali')..."
adb shell "su -c '/data/data/com.offsec.nethunter/scripts/bin/busybox_nh chroot $CHROOT_PATH bash -c \"echo kali | vncpasswd -f > /root/.config/tigervnc/passwd && chmod 600 /root/.config/tigervnc/passwd\" 2>/dev/null || true'"

# 6. Verification
echo "[*] Verifying installation..."
CHROOT_TEST=$(adb shell "su -c '/data/data/com.offsec.nethunter/scripts/bin/busybox_nh chroot $CHROOT_PATH nmap --version 2>&1 | head -n 1'" 2>/dev/null | tr -d '\r' || echo "failed")
echo "[+] Verification output: $CHROOT_TEST"

echo ""
echo "========================================================"
echo "[+] Official Kali NetHunter Suite deployment complete!"
echo "    - NetHunter Console:  Launch 'NetHunter' app"
echo "    - NetHunter Terminal: Launch 'NetHunter Terminal' app"
echo "    - KeX GUI Desktop:    Launch 'NetHunter KeX' or run: kex start"
echo "    - KeX VNC Port:       5901 (Default password: kali)"
echo "========================================================"
