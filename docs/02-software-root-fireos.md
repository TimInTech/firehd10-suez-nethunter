# 02 - Software Root on FireOS (Without Disassembly)

This guide documents how to obtain initial temporary root access on FireOS 5.3.7.3 (Build 40.6.5.9) or similar patched builds, completely via software, without opening the tablet chassis.

---

## 1. Background & Exploit Selection

### Why `mtk-su` Fails on Newer Builds
The popular `mtk-su` binary (CVE-2020-0069) targets the MediaTek Command Queue driver (`/dev/mtk_cmdq`). Amazon backported mitigation patches into FireOS 5.3.7.3 (kernel 3.18.19), tightening SELinux context rules and file permissions:
```
$ ./mtk-su
[-] Can't open /dev/mtk_cmdq: Permission denied
```
Furthermore, the Linux kernel in Build 40.6.5.9 has Dirty-COW (CVE-2016-5195) patched.

### The Working Alternative: Matrix / Wondershare Root Exploit
An offline exploit toolkit based on the KingRoot/Matrix privilege escalation framework (`20165195.zip` + `SuperSU_18+.zip`) remains effective on FireOS 5.3.7.x. It executes in userspace via ADB shell, achieves temporary kernel elevation, installs a minimal SuperSU daemon, and provides root access (`/system/xbin/su`).

---

## 2. Required Files & Checksums

| File | SHA-256 Checksum | Purpose |
|---|---|---|
| `20165195.zip` | `8bfc3d5c75964e5fa28c8ffa39a87249ba10ea4180f55f546b2dcc286a585ea8` | Matrix binary & root exploit scripts |
| `SuperSU_18+.zip` | `b572c1a982d1e0baeb571d3bc0df7f6be11b14553c181c9e0bf737cc4a4fbbfd` | SuperSU payload & su binaries |
| `Superuser.apk` (v2.78 / v2.82) | `2c7be9795a408d6fc74bc7286658dfe12252824867c3a2b726c1f3c78cee918b` | SuperSU GUI management app |

---

## 3. Execution Steps

### Step 1: Prepare the Exploit Directory on Host
Extract both archives into a unified directory named `20165195`:

```bash
mkdir -p 20165195
unzip -q 20165195.zip -d 20165195
unzip -q SuperSU_18+.zip -d 20165195
```

Verify that `20165195/Matrix` and `20165195/su` exist.

### Step 2: Push Exploit to Device
Push the directory to the device's temporary folder and set executable permissions:

```bash
adb push 20165195 /data/local/tmp/
adb shell "chmod 755 /data/local/tmp/20165195/*"
```

### Step 3: Run the Matrix Exploit
Execute the binary via ADB shell:

```bash
adb shell "/data/local/tmp/20165195/Matrix /data/local/tmp/20165195 2"
```

The terminal will produce verbose output as memory corruption occurs. A successful run concludes with:
```
[*] exploited 0x7fab64c000=f97cff8c
end!!!!!!!
<WSRoot><Exploit>0</Exploit></WSRoot>
<WSRoot><Done>0</Done></WSRoot>
```

### Step 4: Verify Temporary Root
Test whether `su` responds:

```bash
adb shell "su -c id"
```
Expected output:
```
uid=0(root) gid=0(root)
```

### Step 5: Install and Configure SuperSU GUI
To prevent FireOS from blocking root prompts in later automation steps, install `Superuser.apk` and set default authorization to **Grant**:

```bash
adb install -r 20165195/Superuser.apk
```

On the tablet screen:
1. Open the **SuperSU** application.
2. If prompted about SU binary update, choose **Normal** (or cancel if it passes).
3. Open **Settings** inside SuperSU.
4. Set **Default access** to **Grant** (instead of Prompt).
5. Uncheck **Show notifications**.

With root confirmed, proceed immediately to the **amonet** bootloader unlock (Step 03).
