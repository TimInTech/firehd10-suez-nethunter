# 06 - Wi-Fi Hardware Analysis & USB-OTG Pentesting

This document details the hardware limitations of the internal MediaTek MT6631 Wi-Fi chipset and provides recommendations and setup guidelines for external USB-OTG wireless adapters.

---

## 1. Internal Wi-Fi: MediaTek MT6631

The Fire HD 10 (2017) uses a combined Wi-Fi/Bluetooth chip connected via an internal SDIO bus (`mtk_sdio_client` on `11260000.sdio`).

### Supported Interface Modes:
Inspecting the PHY configuration via `iw phy phy1 info`:

```
Supported interface modes:
  * IBSS
  * managed
  * AP
  * P2P-client
  * P2P-GO
```

### The Limitation:
- **No Monitor Mode:** The `mtk_sdio_client` / `wlan_mt6630` driver does not expose `monitor` mode. Setting `iw dev wlan0 set type monitor` returns:
  ```
  command failed: Operation not supported (-95)
  ```
- **No Raw Frame Injection:** The firmware lacks 802.11 management/control frame injection hooks required for tools such as `aireplay-ng`, `wifite`, or `mdk4`.
- **Verdict:** The internal Wi-Fi is suitable **only** for network connectivity (SSH, KeX VNC, scanning via `nmap`), not for wireless attacks or frame auditing.

---

## 2. Solution: External USB-OTG Wi-Fi Adapters

The Fire HD 10 kernel supports **USB-OTG Host Mode** (`persist.sys.isUsbOtgEnabled=1`). When an external USB adapter is connected via an OTG adapter, the Linux kernel enumerates the device and loads the appropriate driver module.

### Recommended Chipsets

| Chipset | Driver Module | Bands | Strengths |
|---|---|---|---|
| **Atheros AR9271** (e.g. Alfa AWUS036NHA, TP-Link TL-WN722N v1) | `ath9k_htc` | 2.4 GHz | Native Linux support, rock-solid packet injection, excellent sensitivity |
| **Ralink RT3070 / RT5370** (e.g. Alfa AWUS036NEH) | `rt2800usb` | 2.4 GHz | Low power consumption, native kernel inclusion, stable monitor mode |
| **Realtek RTL8812AU** (e.g. Alfa AWUS036ACH) | `8812au` | 2.4 GHz & 5 GHz | High throughput, dual-band 802.11ac support (requires out-of-tree kernel module) |

---

## 3. Power Requirements & OTG Y-Cable

High-power wireless adapters (such as Alfa AWUS036NHA/ACH) can draw up to **500mA - 1000mA** under active transmission or injection.

The Fire HD 10's Micro-USB port output power is strictly current-limited. Connecting a high-power adapter directly will often cause:
- USB bus resets (`device descriptor read/64, error -71`)
- Brownouts / kernel panics
- Sudden disconnection during frame injection

### Recommended Setup: Active Micro-USB OTG "Y-Cable"
Use a **Micro-USB OTG Y-cable with auxiliary power input**:
1. Male Micro-USB connects to Fire HD 10.
2. Female USB Type-A connects to external Wi-Fi adapter.
3. Male USB Type-A (or female Micro-USB) connects to external power bank or 5V 2A USB charger.

This isolates power delivery while maintaining high-speed USB data communication with the tablet.

---

## 4. Operational Workflow inside NetHunter

Once an external adapter (e.g. AR9271) is connected:

### Step 1: Verify Hardware Enumeration
Inside the NetHunter chroot (`su -c /system/bin/bootkali`):

```bash
lsusb
```
Expected output:
```
Bus 001 Device 003: ID 0cf3:9271 Qualcomm Atheros Communications AR9271 802.11n
```

### Step 2: Check Wireless Interface
```bash
iwconfig
```
Identify the external interface (typically `wlan1`).

### Step 3: Enable Monitor Mode
```bash
airmon-ng start wlan1
```
The interface transitions to `wlan1mon`.

### Step 4: Execute Wireless Pentest Tools
```bash
# Capture packets
airodump-ng wlan1mon

# Automated wireless auditing
wifite -i wlan1mon
```
