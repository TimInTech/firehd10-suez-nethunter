#!/usr/bin/env bash
# backup_lowlevel.sh - Low-Level & Calibration Backup for Amazon Fire HD 10 (suez)
#
# Dumps critical device-unique partitions (proinfo, kb, dkb, metadata)
# and archives /data/nvram (containing Wi-Fi/Bluetooth MAC addresses).
#
# Requirements:
#   - Root shell access via ADB (SuperSU or TWRP)

set -euo pipefail

BACKUP_DIR="${1:-./backup/lowlevel}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TARGET_DIR="${BACKUP_DIR}/${TIMESTAMP}"

echo "[*] Initializing low-level backup for Amazon Fire HD 10 (suez)..."
echo "[*] Target directory: ${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"

# Check ADB connectivity
if ! adb get-state >/dev/null 2>&1; then
    echo "[-] Error: No ADB device detected. Ensure USB debugging or TWRP recovery is active."
    exit 1
fi

DEVICE_MODEL=$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r' || echo "Unknown")
DEVICE_NAME=$(adb shell getprop ro.product.device 2>/dev/null | tr -d '\r' || echo "Unknown")
echo "[+] Detected device: ${DEVICE_MODEL} (${DEVICE_NAME})"

# Identify partition base directory
PART_BASE="/dev/block/platform/mtk-msdc.0/by-name"
if ! adb shell "su -c 'test -d ${PART_BASE}'" 2>/dev/null; then
    PART_BASE="/dev/block/platform/soc/by-name"
fi
echo "[+] Using partition base: ${PART_BASE}"

# List of critical low-level partitions to back up
PARTITIONS=("proinfo" "kb" "dkb" "metadata")

for part in "${PARTITIONS[@]}"; do
    echo "[*] Dumping partition: ${part}..."
    if adb shell "su -c 'test -e ${PART_BASE}/${part}'" 2>/dev/null; then
        adb shell "su -c 'dd if=${PART_BASE}/${part} of=/data/local/tmp/${part}.img bs=512'"
        adb pull "/data/local/tmp/${part}.img" "${TARGET_DIR}/${part}.img"
        adb shell "su -c 'rm -f /data/local/tmp/${part}.img'"
        echo "[+] Successfully backed up: ${part}.img ($(du -h "${TARGET_DIR}/${part}.img" | cut -f1))"
    else
        echo "[!] Warning: Partition ${part} not found in ${PART_BASE}, skipping."
    fi
done

# Backup NVRAM directory (/data/nvram) if available
echo "[*] Checking for /data/nvram calibration data..."
if adb shell "su -c 'test -d /data/nvram'" 2>/dev/null; then
    echo "[*] Archiving /data/nvram..."
    adb shell "su -c 'tar -czf /data/local/tmp/nvram_data.tar.gz -C /data nvram'"
    adb pull "/data/local/tmp/nvram_data.tar.gz" "${TARGET_DIR}/nvram_data.tar.gz"
    adb shell "su -c 'rm -f /data/local/tmp/nvram_data.tar.gz'"
    echo "[+] Successfully archived /data/nvram -> nvram_data.tar.gz"
else
    echo "[!] /data/nvram directory not present or already wiped."
fi

# Generate SHA256 checksums
echo "[*] Calculating SHA256 checksums..."
(
    cd "${TARGET_DIR}"
    sha256sum ./*.img ./*.tar.gz 2>/dev/null > SHA256SUMS || true
)

echo ""
echo "========================================================"
echo "[+] Low-level backup complete: ${TARGET_DIR}"
cat "${TARGET_DIR}/SHA256SUMS"
echo "========================================================"
