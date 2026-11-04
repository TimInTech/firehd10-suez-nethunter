# 04 - LineageOS 14.1 & Magisk Root Flash (Headless)

This guide documents the transition from stock FireOS to **LineageOS 14.1 (Android 7.1.2 Nougat)** with systemless **Magisk 26.4** root, completely automated and headless.

---

## 1. ROM Selection: Why LineageOS 14.1?

| Parameter | LineageOS 14.1 (Android 7.1.2) | LineageOS 16.0 (Android 9.0) |
|---|---|---|
| **System Partition Size** | Fits stock 1.5 GB `/system` layout | Requires manual `parted` repartitioning |
| **Stability** | Battle-tested (7,000+ installs), highly stable | Known deep-sleep drains, Wi-Fi reconnection bugs |
| **Hardware Support** | Camera, audio, hardware acceleration, sensors work | Occasional codec / media playback glitches |
| **Chroot Compatibility** | Full Linux 3.18.19 kernel features available | Same kernel, higher Android background RAM overhead |
| **Recommendation** | **Optimal base for headless pentesting** | Experimental daily driver only |

---

## 2. File Verification & Checksums

| File | Hash / Checksum | Source / Build |
|---|---|---|
| `lineage-14.1-20190926-UNOFFICIAL-suez.zip` | MD5: `93ce115e4aff083047d9b53a8b0fb6b7` | XDA / AndroidFileHost (`fid=1899786940962594323`) |
| `Magisk-v26.4.zip` | SHA-256 verified | Official Magisk GitHub Release |

---

## 3. Automated Headless Flashing

The provided script `scripts/flash_lineageos_headless.sh` performs the entire procedure automatically via ADB and TWRP CLI.

### Run the Script:
```bash
./scripts/flash_lineageos_headless.sh \
  /path/to/lineage-14.1-20190926-UNOFFICIAL-suez.zip \
  /path/to/Magisk-v26.4.zip \
  /path/to/nvram_data.tar.gz
```

---

## 4. Technical Nuances & How the Script Works

### Formatting `/system` via `make_ext4fs`
The TWRP command-line interface (`twrp wipe ...`) supports `data`, `cache`, and `dalvik`, but returns an error when targeting `system`:
```
E:Error with wipe command value: 'system'
```
To achieve a 100% clean installation and wipe all traces of FireOS, the script unmounts `/system` and calls:
```bash
make_ext4fs /dev/block/platform/mtk-msdc.0/by-name/system
```

### Pre-Injecting Host ADB Public Key
Normally, booting into a fresh custom ROM requires unlocking the screen and confirming the RSA fingerprint dialog. To enable **zero-touch headless administration**, the script copies the host's `~/.android/adbkey.pub` directly into `/data/misc/adb/adb_keys` with permissions `640` (`chown 1000:1000`).

As a result, ADB connects immediately as authorized on the first boot.

### Preserving NVRAM & Hardware MACs
On the Fire HD 10, Wi-Fi calibration and MAC addresses are stored in `/data/nvram/APCFG/APRDEB/WIFI`. Formatting `/data` erases this folder, which causes the device to generate a random NVRAM warning or fallback MAC on boot.

The script unpacks `nvram_data.tar.gz` back into `/data/nvram` before the initial system reboot, ensuring the factory MAC address (`50:dc:e7:...`) is preserved.

---

## 5. Post-Boot Headless Provisioning

To prevent LineageOS from halting at the SetupWizard on initial launch, the following commands can be executed via ADB:

```bash
# Bypass SetupWizard
adb shell "settings put global setup_wizard_has_run 1"
adb shell "settings put secure user_setup_complete 1"
adb shell "settings put global device_provisioned 1"

# Prevent screen sleep during setup / pentesting
adb shell "svc power stayon true"
adb shell "settings put system screen_off_timeout 2147483647"
```

---

## 6. Verification Commands

Verify the clean LineageOS installation:

```bash
# Verify Android release
adb shell getprop ro.build.version.release
# Output: 7.1.2

# Confirm total removal of Amazon packages
adb shell "pm list packages | grep -i amazon"
# Output: (empty - 0 packages)

# Confirm Magisk Root
adb shell "su -c id"
# Output: uid=0(root) gid=0(root) context=u:r:magisk:s0
```
