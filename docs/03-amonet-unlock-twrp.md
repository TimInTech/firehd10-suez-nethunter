# 03 - Bootloader Unlock & Permanent TWRP (amonet)

This guide documents the bootloader unlock process using the **amonet** exploit suite created by `k4y0z` and `chaosmaster`. It leverages the **Software BROM Downgrade** method, eliminating the need to pry open the tablet case or short a hardware test point to ground.

---

## 1. How the Exploit Works

Modern FireOS builds enforce strict version checks in the LittleKernel (`lk`) and TrustZone (`tee1`/`tee2`) boot stages:
- Max allowed LK version: `2`
- Max allowed TZ version: `263`
- Max allowed Preloader version: `5`

When software root is already established, `step-1-auto.sh` can overwrite the eMMC boot partition:
1. Disables write protection on `mmcblk0boot0`.
2. Zeros the preloader signature header and writes `EMMC_BOOT`.
3. Flashes vulnerable legacy `lk.bin` and `tz.img` to the device's partitions.
4. Triggers a reboot.

Because the preloader header is invalid, the MediaTek MT8173 BootROM fails to chainload the preloader and falls back into hardware **BootROM (BROM) USB mode** (`0e8d:0003`).

---

## 2. Required amonet Files & Hashes

| File | SHA-256 Checksum | Description |
|---|---|---|
| `amonet-suez-v1.1.2.zip` | `d5f439df03a4ae911bebd05d1c4afaa7e6740ebc596a87c55b5d2571a750f59f` | Full amonet release package for suez |
| `bin/boot0short.img` | `1beb9781b924e1d3977db327f95fd13a70afe24602f997733b7c1b1eb9dac0bc` | Patched eMMC boot0 header |
| `bin/boot.hdr` | `31626faeca01ede8a4d0d871f44f2c66cafbc980a39cd453d412eca8bebeed50` | Exploit header for boot image |
| `bin/boot.payload` | `e0dd07445c57021446199c8ac5a971a2ee16f253a8ee0d2da8d6189697982750` | Micro-loader payload |
| `bin/lk.bin` | `261b5420794d3bd9ba606dfb93b8232b56344273671f6325dc1f17060ede26eb` | Vulnerable LittleKernel |
| `bin/tz.img` | `49e62c7a53b495a75e21f5de59c112a5a5e7c7e3b1b61c14d15b296ce5918407` | Vulnerable TrustZone |
| `bin/twrp.img` | `e856c69d8c6c516c17f12d6d804fce23bbcb023acf1be4b73f52271cb9c23321` | TWRP 3.2.3-0 recovery image |

---

## 3. Step-by-Step Execution

### Step 1: Low-Level Backup (Safety First)
Before modifying partition tables or flashing bootloader binaries, create a full backup of all unique cryptographic and calibration partitions:

```bash
bash scripts/backup_lowlevel.sh
```
This preserves `proinfo.img`, `kb.img`, `dkb.img`, `metadata.img`, and `/data/nvram` (containing your device's unique Wi-Fi/Bluetooth MAC addresses).

---

### Step 2: Run Step 1 (Software BROM Downgrade)
In the amonet working directory on your Linux host:

```bash
sudo ./step-1-auto.sh
```

The script checks versions, detects that `ro.boot.tee_version > 263`, corrupts the preloader safely, flashes vulnerable LK/TZ, and initiates a reboot.

The tablet screen turns off completely and appears unresponsive (black screen). This is the expected hardware BootROM state.

---

### Step 3: Run BootROM Exploit (`bootrom-step.sh`)
Ensure ModemManager is disabled (`sudo systemctl stop ModemManager`).

Disconnect the USB cable, start the script, and reconnect the USB cable:

```bash
sudo ./bootrom-step.sh
```

`modules/main.py` performs the BROM handshake via serial (`0e8d:0003`), exploits the BootROM buffer overflow, disables SLA/DAA authentication, and pushes the custom LK payload.

Once completed, the tablet automatically enumerates in **hacked fastboot** mode (`0bb4:0c01` or `0e8d:0c01`).

---

### Step 4: Run Fastboot Step (`fastboot-step.sh`)
With the tablet in hacked fastboot mode:

```bash
sudo ./fastboot-step.sh
```

This flashes TWRP to `recovery_x`, clears `userdata`, and executes `fastboot oem reboot-recovery`.

The tablet screen displays the **TeamWin Recovery Project (TWRP 3.2.3-0)** interface.

---

### Step 5: Run Step 2 (Finalize GPT Dual-Routing)
With the tablet booted into TWRP and connected via ADB:

```bash
sudo ./step-2.sh
```

What `step-2.sh` does:
1. Dumps and unpatches the stock GPT partition table.
2. Rewrites the partition table with dual-routing entries (`boot` -> `boot_x`, `recovery` -> `recovery_x`).
3. Flashes the amonet payload to the `boot` and `recovery` headers.
4. Flashes the patched preloader to `mmcblk0boot0`.
5. Installs TWRP permanently to `recovery_x`.
6. Reboots into TWRP.

At this point:
- **Bootloader is permanently unlocked.**
- **TWRP 3.2.3-0 is permanently installed on `recovery_x`.**
- Booting normal mode runs `boot_x`; holding Power + Volume Down boots `recovery_x`.
