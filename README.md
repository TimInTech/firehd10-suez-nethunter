# Amazon Fire HD 10 (2017 / suez) — Kali NetHunter & LineageOS Platform

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Device: suez](https://img.shields.io/badge/Device-Amazon_Fire_HD_10_(2017)-orange.svg)](https://en.wikipedia.org/wiki/Fire_HD#Seventh_generation)
[![SoC: MT8173](https://img.shields.io/badge/SoC-MediaTek_MT8173-red.svg)](#hardware-specifications)
[![ROM: LineageOS 14.1](https://img.shields.io/badge/ROM-LineageOS_14.1_(Android_7.1.2)-brightgreen.svg)](docs/04-lineageos-flash.md)
[![Root: Magisk 26.4](https://img.shields.io/badge/Root-Magisk_v26.4-success.svg)](docs/04-lineageos-flash.md)
[![Environment: NetHunter KeX](https://img.shields.io/badge/GUI-TigerVNC_XFCE4_(1920x1200)-blueviolet.svg)](docs/05-nethunter-deployment.md)

This repository provides a **complete, reproducible, and fully automated toolchain** to transform the **Amazon Fire HD 10 (7th Generation, 2017, codename `suez`, model `KFSUWI`)** from a locked, telemetry-heavy FireOS tablet into a clean, debloated, high-performance **Kali NetHunter mobile penetration testing platform**.

---

## 🌟 Key Highlights

- **100% Software-Based:** No opening the case, no prying plastics, and **no hardware test-point grounding required**. Bypasses patched FireOS bootloaders via software BROM downgrade.
- **Zero Amazon Services:** Complete wipe of FireOS; 0 Amazon packages remain. Pure LineageOS 14.1 (Android 7.1.2 Nougat) environment with Trebuchet launcher.
- **Permanent Bootloader Unlock:** amonet exploit suite permanently rewrites partition routing (`boot_x` / `recovery_x`) with TWRP 3.2.3-0 recovery.
- **Modern Root:** Magisk v26.4 systemless root with full SU daemon.
- **Full Kali NetHunter Suite:** Native ARM multi-arch (`armhf`) Debian userspace with thousands of pentesting tools (`nmap`, `metasploit-framework`, `sqlmap`, `aircrack-ng`, `wireshark`, `tshark`, `hydra`, etc.).
- **KeX Remote Desktop GUI:** Full XFCE4 desktop session rendered on TigerVNC at native **1920x1200 resolution**, accessible directly on the device or over the network on port `5901`.
- **Headless & Automatable:** Production-grade Bash scripts for partition backup, TWRP OpenRecoveryScript flashing, and rootfs extraction.

---

## 📐 Architecture & Exploitation Pipeline

```mermaid
flowchart TD
    A["Stock FireOS 5.3.7.3<br/>(Build 40.6.5.9)"] --> B["Matrix Exploit<br/>(/data/local/tmp/20165195/Matrix)"]
    B --> C["Temporary SuperSU Root<br/>(Auto-Grant Configured)"]
    C --> D["Low-Level Partition Backup<br/>(proinfo, kb, dkb, nvram)"]
    D --> E["amonet Software BROM Downgrade<br/>(Corrupt Preloader + Flash Vuln LK/TZ)"]
    E --> F["MediaTek BootROM Mode<br/>(0e8d:0003 BROM Handshake)"]
    F --> G["Hacked Fastboot<br/>(0bb4:0c01 / 0e8d:2000)"]
    G --> H["TWRP 3.2.3-0 Permanent Flash<br/>(Dual-Routing GPT: boot_x & recovery_x)"]
    H --> I["Full Wipe & LineageOS 14.1 Flash<br/>(make_ext4fs /system + Magisk 26.4)"]
    I --> J["NVRAM Restoration & ADB Key Injected<br/>(Factory MACs + Zero-Touch ADB)"]
    J --> K["Kali NetHunter Chroot Deployed<br/>(/data/local/nhsystem/kali-armhf)"]
    K --> L["KeX Desktop & Termux Launcher<br/>(TigerVNC :1 + /system/bin/bootkali)"]
```

---

## 📁 Repository Structure

```
firehd10-suez-nethunter/
├── README.md                          # Main documentation and workflow guide
├── LICENSE                            # MIT License
├── .gitignore                         # Build and artifact exclusions
├── configs/
│   ├── 51-edl-fastboot.rules          # Linux udev rules for MTK BROM, Preloader & Fastboot
│   ├── xstartup                       # XFCE4 desktop startup script for TigerVNC KeX
│   └── termux-bashrc-addon.sh         # Shell alias definitions (nh, kali, kex) for Termux
├── docs/
│   ├── 01-prerequisites.md            # Hardware specs, udev setup, ModemManager fixes
│   ├── 02-software-root-fireos.md     # Offline Matrix root exploit on patched FireOS
│   ├── 03-amonet-unlock-twrp.md       # BROM downgrade, fastboot, and permanent TWRP install
│   ├── 04-lineageos-flash.md          # Headless ROM flash, Magisk root & NVRAM restore
│   ├── 05-nethunter-deployment.md     # Chroot architecture, KeX setup & usage
│   └── 06-hardware-wifi-otg.md        # MT6631 Wi-Fi analysis & USB-OTG adapter guide
└── scripts/
    ├── backup_lowlevel.sh             # Dumps proinfo, kb, dkb, metadata, and /data/nvram
    ├── flash_lineageos_headless.sh    # Automated headless TWRP ROM & Magisk installer
    ├── deploy_nethunter.sh            # Extracts rootfs, configures KeX, installs bootkali
    ├── bootkali                       # Android chroot launcher script with clean env
    ├── kex                            # TigerVNC / XFCE4 KeX lifecycle manager
    └── setup_termux_aliases.sh        # Injects shortcuts into Termux on device
```

---

## 🔐 Verified Checksums (SHA-256 / MD5)

All external archives used throughout this workflow have been tested and verified:

| File Name | Size | Checksum | Function |
|---|---|---|---|
| `20165195.zip` | 4.8 MB | SHA-256: `8bfc3d5c75964e5fa28c8ffa39a87249ba10ea4180f55f546b2dcc286a585ea8` | Matrix root exploit binary & scripts |
| `SuperSU_18+.zip` | 4.9 MB | SHA-256: `b572c1a982d1e0baeb571d3bc0df7f6be11b14553c181c9e0bf737cc4a4fbbfd` | SuperSU su binaries & payload |
| `Superuser.apk` (v2.82) | 5.9 MB | SHA-256: `2c7be9795a408d6fc74bc7286658dfe12252824867c3a2b726c1f3c78cee918b` | SuperSU root permission manager APK |
| `amonet-suez-v1.1.2.zip` | 13.9 MB | SHA-256: `d5f439df03a4ae911bebd05d1c4afaa7e6740ebc596a87c55b5d2571a750f59f` | amonet BROM exploit & payload suite |
| `lineage-14.1-20190926-UNOFFICIAL-suez.zip` | 381 MB | MD5: `93ce115e4aff083047d9b53a8b0fb6b7` | Stable LineageOS 14.1 ROM for suez |
| `Magisk-v26.4.zip` | 11.9 MB | SHA-256: Official Release | Magisk root flashable package |
| `kali-nethunter-rootfs-full-armhf.tar.xz` | 1.7 GB | Official Kali Release | Full Kali NetHunter ARMHF root filesystem |
| `com.termux_118.apk` | 97 MB | Official F-Droid / GitHub | Modern Termux terminal emulator |

---

## 🚀 Quick Start Guide

### Phase 1: Host Preparation & Safety Backup
1. Install prerequisites and stop ModemManager:
   ```bash
   sudo apt install -y adb fastboot python3 python3-serial dos2unix
   sudo systemctl stop ModemManager && sudo systemctl disable ModemManager
   sudo cp configs/51-edl-fastboot.rules /etc/udev/rules.d/ && sudo udevadm trigger
   ```
2. Enable Developer Options & ADB on FireOS (tap Serial Number 7 times).
3. Gain temporary root using Matrix exploit (see [docs/02-software-root-fireos.md](docs/02-software-root-fireos.md)).
4. Perform low-level backup of critical calibration partitions:
   ```bash
   bash scripts/backup_lowlevel.sh
   ```

### Phase 2: Permanent Bootloader Unlock & TWRP
1. Run software BROM downgrade via amonet:
   ```bash
   cd amonet-suez-v1.1.2/amonet
   sudo ./step-1-auto.sh
   ```
2. Exploit BootROM handshake:
   ```bash
   sudo ./bootrom-step.sh
   ```
3. Flash TWRP into hacked fastboot:
   ```bash
   sudo ./fastboot-step.sh
   ```
4. Finalize dual-routing partition table:
   ```bash
   sudo ./step-2.sh
   ```
*(Details in [docs/03-amonet-unlock-twrp.md](docs/03-amonet-unlock-twrp.md))*

### Phase 3: Flash LineageOS 14.1 & Magisk (Headless)
Execute the headless flashing script:
```bash
./scripts/flash_lineageos_headless.sh \
  lineage-14.1-20190926-UNOFFICIAL-suez.zip \
  Magisk-v26.4.zip \
  backup/lowlevel/<timestamp>/nvram_data.tar.gz
```
*(Details in [docs/04-lineageos-flash.md](docs/04-lineageos-flash.md))*

### Phase 4: Deploy Kali NetHunter & KeX
Deploy rootfs, configure wrappers, and initialize KeX:
```bash
./scripts/deploy_nethunter.sh \
  kali-nethunter-rootfs-full-armhf.tar.xz \
  com.termux_118.apk
```
*(Details in [docs/05-nethunter-deployment.md](docs/05-nethunter-deployment.md))*

---

## 🖥️ Operating Kali NetHunter

### Command-Line Interface (CLI)
From your computer:
```bash
adb shell "su -c /system/bin/bootkali"
```
Or directly on the tablet inside Termux:
```bash
nh
# or:
kali
```

### KeX Remote Desktop GUI
Start the VNC server on display `:1` (port `5901`):
```bash
su -c /system/bin/kex start
```
Connect any VNC client (VNC Viewer, Remmina, TigerVNC) to:
- Host: `127.0.0.1:5901` (on-device) or `<tablet-ip>:5901` (over network)
- Password: `kali` (configurable via `kex passwd`)

---

## 📡 Wi-Fi Pentesting & Hardware Realities

The Fire HD 10 contains an internal **MediaTek MT6631 SDIO** wireless chip.
- **Limitation:** The internal driver does **NOT support monitor mode** or raw 802.11 packet injection (`iw phy phy1 info` confirms only `managed`, `AP`, `P2P`).
- **Solution:** Connect an external USB Wi-Fi adapter via a **Micro-USB OTG Y-Cable** with auxiliary 5V power injection.
  - Recommended: **Atheros AR9271** (`ath9k_htc`) or **Ralink RT3070** (`rt2800usb`).

See [docs/06-hardware-wifi-otg.md](docs/06-hardware-wifi-otg.md) for full hardware compatibility matrices and wiring advice.

---

## ✅ Live Verification & Sanity Checks

Verified on real hardware:

```bash
$ adb shell getprop ro.build.version.release
7.1.2

$ adb shell "pm list packages | grep -i amazon"
(empty - 0 packages)

$ adb shell "su -c id"
uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0

$ adb shell "su -c '/system/bin/bootkali nmap --version'"
Nmap version 7.99 ( https://nmap.org )
Platform: arm-unknown-linux-gnueabihf
```

---

## ⚖️ Disclaimer & Acknowledgments

- **Disclaimer:** Modifying bootloaders, flashing custom ROMs, and writing low-level partitions can potentially brick your device if instructions are not followed carefully. Always verify your device model (`suez` / `KFSUWI`) and keep low-level partition backups.
- **Credits:**
  - `k4y0z` & `chaosmaster` for the revolutionary [amonet](https://github.com/chaosmaster/amonet) BootROM exploit suite.
  - `retyre` & `3ch01c` for preserving the offline Matrix root method.
  - LineageOS and Offensive Security (Kali NetHunter) development teams.

---

**Author:** [TimInTech](https://github.com/TimInTech)
