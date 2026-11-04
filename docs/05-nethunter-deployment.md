# 05 - Kali NetHunter Chroot & KeX Remote Desktop

This guide explains the deployment and operation of the Kali Linux NetHunter environment on the Amazon Fire HD 10 using a native `armhf` multi-arch chroot, TigerVNC KeX server, and Termux integration.

---

## 1. Architecture Overview

```
+-------------------------------------------------------------+
|                     Android 7.1.2 Host                      |
|                  LineageOS 14.1 (64-bit Kernel)             |
|                                                             |
|  [Termux UI]            [VNC Viewer App / Network Client]   |
|       |                                |                    |
|       v (su)                           v (:5901)            |
|  /system/bin/bootkali           TigerVNC Server             |
|       |                                |                    |
|       +--------------------------------+                    |
|                       |                                     |
|                       v                                     |
|    +---------------------------------------------------+    |
|    |      Kali NetHunter Chroot (/data/local/nhsystem) |    |
|    |                                                   |    |
|    |  Debian armhf Userspace (Kali Rolling)            |    |
|    |  XFCE4 Desktop Session                            |    |
|    |  Full Pentest Toolchain:                          |    |
|    |    - nmap, metasploit, sqlmap, nikto              |    |
|    |    - aircrack-ng, wireshark, tshark, tcpdump      |    |
|    |    - hydra, john, responder, hashcat              |    |
|    +---------------------------------------------------+    |
+-------------------------------------------------------------+
```

### Why `armhf` (32-bit Multi-Arch)?
While the MediaTek MT8173 features a 64-bit Cortex-A72/A53 CPU and 64-bit Linux 3.18 kernel, the 32-bit `armhf` rootfs provides significant advantages for this 2 GB RAM device:
1. **Low Memory Overhead:** 32-bit pointers reduce memory consumption across all running binaries and daemons by ~30%, preventing Out-Of-Memory (OOM) pressure.
2. **Binary Compatibility:** Precompiled ARM pentesting utilities and exploit frameworks run natively with zero emulation overhead.
3. **Hardware Compatibility:** ARMHF toolchains align cleanly with legacy MediaTek wireless/sensor libraries.

---

## 2. Automated Deployment

Use `scripts/deploy_nethunter.sh` to install everything in a single step:

```bash
./scripts/deploy_nethunter.sh \
  /path/to/kali-nethunter-rootfs-full-armhf.tar.xz \
  /path/to/com.termux_118.apk
```

The script:
1. Pushes and extracts the 1.7 GB compressed archive into `/data/local/nhsystem/kali-armhf` (~4.7 GB uncompressed).
2. Installs `/system/bin/bootkali` (chroot launcher).
3. Installs `/system/bin/kex` (KeX VNC manager).
4. Configures TigerVNC (`~/.config/tigervnc/xstartup`) with XFCE4.
5. Injects aliases into Termux (`nh`, `kali`, `kex`).
6. Verifies the toolchain (`nmap --version`).

---

## 3. Entering the Chroot (CLI)

### From Host via ADB:
```bash
adb shell "su -c /system/bin/bootkali"
```

### From Device via Termux:
Open Termux and simply type:
```bash
nh
# or:
kali
```

### Running One-Off Commands:
```bash
adb shell "su -c '/system/bin/bootkali nmap -sV -p 80,443 192.168.1.1'"
```

---

## 4. KeX (NetHunter Desktop Experience)

KeX runs an XFCE4 desktop session over TigerVNC, tailored for the Fire HD 10's native 1920x1200 resolution.

### Controlling KeX:
```bash
# Start KeX server on display :1 (port 5901)
su -c /system/bin/kex start

# Check KeX status
su -c /system/bin/kex status

# Stop KeX server
su -c /system/bin/kex stop

# Change VNC password
su -c /system/bin/kex passwd
```

### Connecting to KeX:
- **On Device:** Open NetHunter KeX app or any VNC Viewer app, set connection to `127.0.0.1:5901`, password `kali`.
- **From Workstation / PC:** Connect your VNC viewer (TigerVNC, RealVNC, Remmina) to `<tablet-ip>:5901`, password `kali`.

---

## 5. Chroot Technical Fixes

### Resolving `libsigchain.so` Conflicts
Android exports `LD_PRELOAD` pointing to Android runtime libraries. When entering a Debian chroot, `ld.so` attempts to load Android libraries into Debian binaries, producing:
```
ERROR: ld.so: object 'libsigchain.so' from LD_PRELOAD cannot be preloaded
```
`scripts/bootkali` explicitly executes `unset LD_PRELOAD` prior to invoking `/system/bin/chroot`.

### DNS Resolver Routing
To ensure consistent network resolution inside the chroot regardless of Android's internal `netd` daemon, `scripts/bootkali` binds `/etc/resolv.conf` to public recursive resolvers:
```
nameserver 1.1.1.1
nameserver 8.8.8.8
```
