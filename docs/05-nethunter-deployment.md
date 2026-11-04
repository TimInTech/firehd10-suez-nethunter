# 05 - Full Kali NetHunter App Suite & KeX Remote Desktop

This guide explains the deployment, configuration, and operation of the **official Kali NetHunter App Suite** on the Amazon Fire HD 10 (`suez`), featuring the native NetHunter Management Console, NetHunter Terminal (`nhterm`), NetHunter KeX (VNC Desktop), NetHunter Store, and a full Debian `armhf` multi-arch chroot.

---

## 1. Architecture Overview

```
+-----------------------------------------------------------------------------------+
|                        Amazon Fire HD 10 (suez) - Android 7.1.2                   |
|                             LineageOS 14.1 (Kernel 3.18.19)                       |
|                                                                                   |
|  +-----------------------------------------------------------------------------+  |
|  |                 Official Offensive Security NetHunter App Suite             |  |
|  |                                                                             |  |
|  |  [NetHunter App]      [NetHunter Terminal]    [NetHunter KeX]   [NH Store]  |  |
|  |  (com.offsec.nethunter) (com.offsec.nhterm)    (com.offsec.kex)  (F-Droid)   |  |
|  |        |                        |                    |                      |  |
|  |        v                        v                    v                      |  |
|  |  Services & Chroot Mgr     Kali/SU Shell Tabs    VNC Client (1920x1200)     |  |
|  |  (Apache, MSF, SSH, BeEF)  (/system/bin/bootkali)  (Port 5901 - Display :1)   |  |
|  +-----------------------------------------------------------------------------+  |
|                                         |                                         |
|                                         v (Magisk Root / su)                      |
|  +-----------------------------------------------------------------------------+  |
|  |             Kali NetHunter Rootfs (/data/local/nhsystem/kali-armhf)         |  |
|  |                                                                             |  |
|  |  Debian Userspace (Kali Rolling armhf)                                      |  |
|  |  TigerVNC Server 1.13 + XFCE4 Desktop Session                               |  |
|  |  Shared Data Storage: /storage/emulated/0/nh_files/                         |  |
|  |    - duckyscripts, modules, templates, usb_exfil                            |  |
|  |  Full Penetration Testing Arsenal:                                         |  |
|  |    - nmap, metasploit-framework, sqlmap, nikto, hydra                       |  |
|  |    - aircrack-ng, wireshark, tshark, tcpdump, responder                     |  |
|  +-----------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------+
```

---

## 2. Official NetHunter Application Components

The ecosystem consists of four core Offensive Security applications:

| Application | Package Identifier | Functionality |
|---|---|---|
| **NetHunter App** | `com.offsec.nethunter` | Master control console: Chroot Manager, Kali Services (Apache, SSH, Metasploit, BeEF), USB Arsenal (BadUSB / HID / Tethering), DuckHunter, MITM, MAC Changer |
| **NetHunter Terminal** | `com.offsec.nhterm` | Multi-tab NeoTerm terminal emulator with dedicated tabs for `KALI`, `ANDROID`, and `ANDROID SU` |
| **NetHunter KeX** | `com.offsec.nethunter.kex` | Official client for remote/local XFCE4 desktop sessions over TigerVNC |
| **NetHunter Store** | `com.offsec.nethunter.store` | F-Droid client repository providing updates for all NetHunter security utilities |

---

## 3. Package Checksums (SHA-256)

Verified on actual hardware (`suez`):

| Package / Artifact | Version | SHA-256 Checksum |
|---|---|---|
| `kali-nethunter-rootfs-full-armhf.tar.xz` | Kali Rolling | `636f...` (Official OffSec Release) |
| `com.offsec.nethunter` (NetHunter App) | `2026.3` | `8bd29db16a06f22c3ef341849bd13b73338d0be1f4f8a75bab5d50b0fbf52f10` |
| `com.offsec.nhterm` (NetHunter Terminal) | `2025.4` | `f190aa87e05c5a8473644cd1bed471d4427d2ba9d30b2e50c83a5eacaa3d54d5` |
| `com.offsec.nethunter.kex` (NetHunter KeX) | `v5.2.5-1` | `768dc86613f9a8b46b09ee37ba303806283497487dc029d79226bd0a09886b4f` |
| `com.offsec.nethunter.store` (NetHunter Store)| `2019.3b` | `54661b4f326c65cd6037186dc7a503b2473a3b011ca0913244b13b056ac0c06e` |

---

## 4. Automated Full Suite Deployment

The provided script `scripts/deploy_nethunter.sh` automates the entire installation:
1. Pushes and extracts the Kali rootfs to `/data/local/nhsystem/kali-armhf`.
2. Installs all four NetHunter APKs.
3. Configures `/data/data/com.offsec.nethunter/shared_prefs/com.offsec.nethunter.xml` so the NetHunter App immediately detects the chroot without requiring manual setup.
4. Initializes the NetHunter boot scripts and symlinks in `/system/bin/` (`bootkali`, `bootkali_bash`, `bootkali_login`, `killkali`, `busybox_nh`).
5. Configures TigerVNC (`~/.config/tigervnc/xstartup`) with XFCE4 and sets default KeX credentials.

### Run Deployment:
```bash
./scripts/deploy_nethunter.sh /path/to/kali-nethunter-rootfs-full-armhf.tar.xz /path/to/apks/
```

---

## 5. Operating Kali NetHunter

### A. NetHunter Terminal (`nhterm`)
Launch **NetHunter Terminal** directly from the LineageOS app drawer:
- **KALI Tab:** Spawns an interactive login shell inside the Kali chroot (`su -c /system/bin/bootkali_login`).
- **ANDROID SU Tab:** Spawns an Android root shell with full access to block devices and hardware props.
- **ANDROID Tab:** Standard unprivileged Android shell.

### B. NetHunter Core App
Open the **NetHunter** app:
- **Kali Services:** Toggle background services on/off with a single tap:
  - Apache Web Server (`service apache2 start/stop`)
  - OpenSSH Server (`service ssh start/stop`)
  - Metasploit RPC Daemon (`service metasploit start/stop`)
  - BeEF XSS Framework (`service beef-xss start/stop`)
- **Chroot Manager:** Inspect chroot storage status, mounts, and backup images.
- **DuckHunter / HID:** Deploy Ducky script keystroke injection payloads.
- **Custom Commands:** Run predefined one-tap reconnaissance and auditing routines.

### C. KeX (Desktop GUI on Tablet Screen)
1. Open **NetHunter** > **KeX Manager** and tap **Start Server** (or run `kex start` in terminal).
2. Tap **Open KeX Client** (or open the **NetHunter KeX** app).
3. Connect with:
   - **Host:** `127.0.0.1` (or leave default)
   - **Port:** `5901`
   - **Password:** `kali`
4. The full Kali Linux XFCE4 desktop appears at the tablet's native **1920x1200** resolution.

---

## 6. Remote Access (Headless Workstation Workflow)

When the tablet is connected to Wi-Fi or USB tethering, the NetHunter environment can be operated entirely from your primary PC:

### Remote CLI via ADB / SSH:
```bash
# Direct ADB shell into chroot
adb shell "su -c /system/bin/bootkali"

# Or via SSH (if SSH service was enabled in NetHunter App)
ssh root@<tablet-ip> -p 22
```

### Remote KeX Desktop via Workstation:
Connect your desktop VNC viewer (TigerVNC, RealVNC, Remmina) to `<tablet-ip>:5901` (password `kali`).

---

## 7. Operational Scripts in `/system/bin`

The NetHunter App links the following utilities into `/system/bin`:

| Binary / Symlink | Target | Function |
|---|---|---|
| `bootkali` | `.../scripts/bootkali` | Launches services or interactive chroot |
| `bootkali_login` | `.../scripts/bootkali_login` | Spawns clean interactive login shell (`su -l`) |
| `bootkali_bash` | `.../scripts/bootkali_bash` | Non-login bash shell inside Kali chroot |
| `killkali` | `.../scripts/killkali` | Safely unmounts all chroot virtual filesystems |
| `busybox_nh` | `.../scripts/bin/busybox_nh` | Dedicated multi-call busybox binary |
| `kex` | `/usr/bin/kex` | Starts/stops TigerVNC on port 5901 |
