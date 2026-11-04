# 01 - Prerequisites & Host Preparation

This guide covers the necessary hardware, host system preparation, udev rules, and device settings required to unlock, flash, and deploy Kali NetHunter on the Amazon Fire HD 10 (7th Gen, 2017, codename `suez`).

---

## 1. Hardware Specifications

| Property | Details |
|---|---|
| **Device** | Amazon Fire HD 10 (7th Generation, 2017) |
| **Model Number** | `KFSUWI` |
| **Codename / Board** | `suez` |
| **SoC** | MediaTek MT8173 (Quad-Core: 2x Cortex-A72 @ 2.1 GHz + 2x Cortex-A53 @ 1.7 GHz) |
| **Architecture** | AArch64 (64-bit kernel, 64-bit userland support) |
| **RAM** | 2 GB LPDDR3 |
| **Internal Storage** | 32 GB or 64 GB eMMC |
| **Display** | 10.1" IPS, 1920 x 1200 (16:10, 224 ppi) |
| **Internal Wi-Fi** | MediaTek MT6631 SDIO (802.11 a/b/g/n/ac) |
| **USB Interface** | Micro-USB 2.0 with USB-OTG Host support |

---

## 2. Host System Requirements

A Linux host (Ubuntu 20.04/22.04/24.04, Debian 11/12, or Kali Linux) is strongly recommended.

### Required Host Packages
Install ADB, Fastboot, Python 3, pyserial, and utility packages:

```bash
sudo apt update
sudo apt install -y adb fastboot python3 python3-serial dos2unix tar xz-utils curl wget
```

### Critical: Disable ModemManager
ModemManager claims serial ports automatically and probes them with AT commands. When the MediaTek SoC enters BootROM mode (`0e8d:0003`), ModemManager will intercept the handshake and cause the exploit to fail with timeout errors.

Disable ModemManager prior to flashing:
```bash
sudo systemctl stop ModemManager
sudo systemctl disable ModemManager
```

---

## 3. Configure Udev Rules

Create `/etc/udev/rules.d/51-edl-fastboot.rules` (or copy the provided config file from `configs/51-edl-fastboot.rules`):

```bash
sudo cp configs/51-edl-fastboot.rules /etc/udev/rules.d/51-edl-fastboot.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Ensure your user belongs to the `plugdev` group:
```bash
sudo usermod -aG plugdev "$USER"
```

---

## 4. Prepare the Fire HD 10 (Stock FireOS)

1. Power on the tablet.
2. If performing initial setup, skip Wi-Fi configuration (choose an access point, then tap *Not now* / *Cancel*) to prevent background OTA updates.
3. Open **Settings** > **Device Options**.
4. Tap **Serial Number** 7 times repeatedly until *You are now a developer!* appears.
5. Tap the new **Developer Options** menu item.
6. Toggle **Enable ADB** to ON.
7. Connect the tablet to your Linux host via a high-quality Micro-USB data cable.
8. On the tablet screen, accept the USB Debugging prompt and check *Always allow from this computer*.

Verify the device connection on your Linux host:
```bash
adb devices -l
```
Expected output:
```
List of devices attached
G000xxxxxxxxxxxx    device product:suez model:KFSUWI device:suez
```
