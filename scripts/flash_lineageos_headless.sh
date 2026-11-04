#!/usr/bin/env bash
# flash_lineageos_headless.sh - Headless Custom-ROM & Magisk Flasher for suez
#
# Automates:
#   1. Verification of TWRP recovery mode
#   2. Full wipe (/system format, data/cache/dalvik wipe)
#   3. ROM & Magisk installation via TWRP OpenRecoveryScript / CLI
#   4. Restoration of NVRAM calibration data
#   5. Pre-authorization of host ADB public key (~/.android/adbkey.pub)
#   6. Reboot into LineageOS 14.1
#
# Usage:
#   ./flash_lineageos_headless.sh <path-to-lineageos.zip> <path-to-magisk.zip> [path-to-nvram_data.tar.gz]

set -euo pipefail

ROM_ZIP="${1:-}"
MAGISK_ZIP="${2:-}"
NVRAM_ARCHIVE="${3:-}"

if [ -z "$ROM_ZIP" ] || [ ! -f "$ROM_ZIP" ]; then
    echo "[-] Error: Please specify a valid LineageOS ZIP file."
    echo "Usage: $0 <lineage-14.1-*-suez.zip> <Magisk-*.zip> [nvram_data.tar.gz]"
    exit 1
fi

if [ -z "$MAGISK_ZIP" ] || [ ! -f "$MAGISK_ZIP" ]; then
    echo "[-] Error: Please specify a valid Magisk ZIP file."
    echo "Usage: $0 <lineage-14.1-*-suez.zip> <Magisk-*.zip> [nvram_data.tar.gz]"
    exit 1
fi

echo "[*] Target ROM:    $ROM_ZIP"
echo "[*] Target Magisk: $MAGISK_ZIP"
[ -n "$NVRAM_ARCHIVE" ] && echo "[*] Target NVRAM:  $NVRAM_ARCHIVE"

# Wait for ADB
echo "[*] Checking ADB connection..."
adb wait-for-device

# Verify or enter TWRP Recovery
MODE=$(adb shell getprop ro.bootmode 2>/dev/null | tr -d '\r' || true)
if [ "$MODE" != "recovery" ]; then
    echo "[*] Device is not in recovery mode. Rebooting to TWRP recovery..."
    adb reboot recovery
    echo "[*] Waiting for TWRP to initialize..."
    sleep 15
    adb wait-for-device
fi

echo "[+] Confirmed TWRP recovery environment."

# Unmount /system and /data before formatting
adb shell "umount /system 2>/dev/null || true"
adb shell "umount /data 2>/dev/null || true"

# 1. Format /system directly with make_ext4fs
echo "[*] Formatting /system partition..."
PART_SYSTEM="/dev/block/platform/mtk-msdc.0/by-name/system"
adb shell "make_ext4fs $PART_SYSTEM"

# 2. Perform TWRP wipe on cache, dalvik, and data
echo "[*] Wiping cache, dalvik, and data..."
adb shell "twrp wipe cache"
adb shell "twrp wipe dalvik"
adb shell "twrp wipe data"

# 3. Mount /data and /sdcard
adb shell "mount /data 2>/dev/null || true"
adb shell "mount /sdcard 2>/dev/null || true"

# 4. Push ROM and Magisk to /sdcard
echo "[*] Pushing ROM to /sdcard/rom.zip..."
adb push "$ROM_ZIP" /sdcard/rom.zip

echo "[*] Pushing Magisk to /sdcard/magisk.zip..."
adb push "$MAGISK_ZIP" /sdcard/magisk.zip

# 5. Flash via TWRP CLI
echo "[*] Flashing LineageOS 14.1..."
adb shell "twrp install /sdcard/rom.zip"

echo "[*] Flashing Magisk..."
adb shell "twrp install /sdcard/magisk.zip"

# Clean up pushed zip files to save space
adb shell "rm -f /sdcard/rom.zip /sdcard/magisk.zip"

# 6. Restore NVRAM calibration data if provided
if [ -n "$NVRAM_ARCHIVE" ] && [ -f "$NVRAM_ARCHIVE" ]; then
    echo "[*] Restoring NVRAM calibration data to /data/nvram..."
    adb push "$NVRAM_ARCHIVE" /data/nvram_data.tar.gz
    adb shell "tar -xzf /data/nvram_data.tar.gz -C /data"
    adb shell "rm -f /data/nvram_data.tar.gz"
    adb shell "chown -R root:root /data/nvram && chmod -R 770 /data/nvram"
    echo "[+] NVRAM restored."
fi

# 7. Pre-inject host ADB key for headless authorization
ADB_PUB_KEY="${HOME}/.android/adbkey.pub"
if [ -f "$ADB_PUB_KEY" ]; then
    echo "[*] Injecting host ADB public key (${ADB_PUB_KEY}) into /data/misc/adb/adb_keys..."
    adb shell "mkdir -p /data/misc/adb"
    adb push "$ADB_PUB_KEY" /data/misc/adb/adb_keys
    adb shell "chmod 640 /data/misc/adb/adb_keys"
    adb shell "chown 1000:1000 /data/misc/adb/adb_keys 2>/dev/null || chown 0:0 /data/misc/adb/adb_keys"
    echo "[+] ADB public key pre-authorized."
fi

echo "[*] Flashing and setup complete. Rebooting into LineageOS 14.1..."
adb reboot

echo "[*] Device reboot initiated. Allow 2-3 minutes for the first boot."
echo "[+] Done."
