# Oolite-MT7987A Firmware Update and Flashing Guide

This guide describes how to install or update firmware on the GainStrong
Oolite-MT7987A module using the public OpenWrt 25.12 support branch.

It covers every situation a customer can realistically meet, including the
case where **you have the bare module only** — no carrier board, no Ethernet
port, and possibly blank flash. In that situation the only available channels
are **the serial UART console** and **Wi-Fi**.

## 1. Scope and prerequisites

This guide covers installing and updating the OpenWrt system on the GainStrong
Oolite-MT7987A module.

### Files you will use

| File | Purpose |
| --- | --- |
| `*-squashfs-sysupgrade.itb` | System image written into the firmware region |
| `*-initramfs-recovery.itb` | RAM-only system used for recovery and installation |
| `mediatek-filogic.manifest` | Package list for the build |
| `SHA256SUMS` | Digests for verifying your download |

Two conditions must already be true for the module to run:

1. **A compatible bootloader is installed.** It must load the FIT from the
   active boot medium and select the matching device-tree overlay.
2. **Valid device-specific Factory calibration data is present.** Calibration
   is unique to each device and cannot be regenerated from a system image.
   WiFi is not considered supported until real calibration data exists.

If either condition is missing, see
[Section 10](#10-path-f-uart-bootrom-recovery-blank-or-bricked).

### Build artifacts

```text
openwrt-*-mediatek-filogic-gainstrong_oolite-mt7987a-squashfs-sysupgrade.itb
openwrt-*-mediatek-filogic-gainstrong_oolite-mt7987a-initramfs-recovery.itb
```

The sysupgrade FIT is limited to **31,232 KiB**. The same artifact is used for
every boot medium; the pre-installed bootloader selects the active overlay.

The **initramfs-recovery** image runs entirely from RAM. It is the key tool for
recovering a module that has no usable system on flash, and it is small enough
to be transferred over a serial link.

## 2. Before you start

1. **Verify the download.** Compare the file against `SHA256SUMS` from the same
   release before writing anything.
2. **Identify the boot medium.** Read `Boot media:` in the U-Boot banner, or
   check `/proc/mtd`, `ubinfo -a`, or the GPT table from a running system.
3. **Record the layout.** See [Section 3](#3-memory-layout-by-boot-medium).
4. **Back up what you cannot regenerate.** At minimum the `Factory` partition
   and, if you still have a working boot chain, the `bootloader` region.
5. **Use stable power.** Never remove power during an erase or write.

### Serial console parameters

```text
115200 baud, 8 data bits, no parity, 1 stop bit, no flow control
```

UART voltage must match the module. Cross-connect TX and RX and share a common
ground. Do not use RS-232 levels, and do not power the module from the USB
adapter's power pin.

## 3. Memory layout by boot medium

### SPI-NOR

| Offset | Size | Content |
| --- | ---: | --- |
| `0x000000` | `0x040000` | BL2 |
| `0x040000` | `0x0a0000` | FIP |
| `0x0e0000` | `0x010000` | `ubootenv` |
| `0x0f0000` | `0x010000` | `Factory` |
| `0x100000` | remaining | `firmware` FIT |

### SPI-NAND

| Offset | Size | Content |
| --- | ---: | --- |
| `0x000000` | `0x060000` | BL2 window |
| `0x060000` | `0x1a0000` | raw FIP fallback |
| `0x200000` | `0x100000` | reserved, kept erased |
| `0x300000` | remaining | UBI |

UBI volumes, in fixed order: `fip`, `Factory`, `ubootenv`, `fit`, `rootfs_data`.

### SD and eMMC (user-area GPT)

| Partition | Start | Size |
| --- | ---: | ---: |
| `bl2` | 17K | 1007K |
| `fip` | 1M | 2M |
| `Factory` | 3M | 256K |
| `ubootenv` | 3.25M | 256K |
| `firmware` | 3.5M | configured rootfs size |

**`sysupgrade` only ever writes the `firmware` / `fit` region of the active
medium.** It never touches the bootloader, U-Boot environment, or Factory.

## 4. Choosing an update path

| Situation | Recommended path | Section |
| --- | --- | --- |
| OpenWrt already boots | `sysupgrade` over SSH or LuCI | [5](#5-path-a-sysupgrade-from-a-running-system) |
| Carrier board with Ethernet, can reach U-Boot | Web Recovery | [6](#6-path-b-u-boot-web-recovery-ethernet-required) |
| Carrier board with Ethernet, prefer scripted control | TFTP + `mtd` | [7](#7-path-c-u-boot-tftp-and-manual-write-ethernet-required) |
| **Bare module, no Ethernet, U-Boot reachable** | UART console + YMODEM | [8](#8-path-d-serial-uart-transfer-module-only) |
| **Bare module, no Ethernet, large image** | UART → initramfs → **Wi-Fi** → SSH | [9](#9-path-e-wi-fi-update-module-only-recommended-for-bare-modules) |
| **Flash completely blank, or no boot at all** | UART BootROM download + full restore | [10](#10-path-f-uart-bootrom-recovery-blank-or-bricked) |
| Bare flash chip, before assembly | External SPI programmer | [11](#11-path-g-external-programmer-before-assembly) |

> **Important for bare modules.** With no carrier board there is no Ethernet
> port, so Web Recovery and TFTP are unavailable. Plan on the serial console,
> and use Wi-Fi as the bulk transfer channel once a RAM system is running.

## 5. Path A: sysupgrade from a running system

This is the normal upgrade path and preserves the bootloader, environment, and
Factory data.

Copy the image to the device, then:

```sh
sysupgrade /tmp/openwrt-*-gainstrong_oolite-mt7987a-squashfs-sysupgrade.itb
```

Use `sysupgrade -n` when settings from an older or unrelated image must not be
retained:

```sh
sysupgrade -n /tmp/openwrt-*-gainstrong_oolite-mt7987a-squashfs-sysupgrade.itb
```

Alternatively use LuCI at `http://192.168.1.1/` → **System → Flash Firmware**.
Do not power off until the device reboots on its own.

## 6. Path B: U-Boot Web Recovery (Ethernet required)

Web Recovery is a browser-based recovery service inside the installed
bootloader. It is the most convenient update method **once you have a working
Ethernet port** — but that condition is exactly what most bare-module users do
not have, so read this section carefully before planning around it.

### 6.1 Prerequisite: a working Ethernet port

> **Oolite-MT7987A is a module. It does not carry an RJ45 connector of its
> own.** The Ethernet port, if you have one at all, comes from your carrier
> board. Web Recovery is impossible without it.

Sources of an Ethernet port:

| Source | Notes |
| --- | --- |
| Carrier board RJ45 wired to the MT7987 internal 2.5 GbE PHY | The normal case. Appears as the `lan` interface. |
| Carrier board Ethernet switch chip | Provides multiple LAN ports; needs matching support in your bootloader build. |
| USB Ethernet adapter | Only works if your bootloader build carries the USB host and adapter drivers. Not guaranteed — check with GainStrong. |

Before relying on Web Recovery, confirm the port actually links:

- Watch the console for link status when you plug in a cable.
- In U-Boot, `printenv ipaddr` shows the address the service will use.
- A status LED on your carrier board may indicate bootloader activity.

**If you have no Ethernet port, Web Recovery is unavailable.** Use
[Path D](#8-path-d-serial-uart-transfer-module-only) or
[Path E](#9-path-e-wi-fi-update-module-only-recommended-for-bare-modules)
instead. Do not plan a production flow around Web Recovery until the port is
proven working on your own hardware.

### 6.2 Entering Web Recovery

> Web Recovery is a feature of the bootloader installed on your module. Its
> exact menu wording and available targets depend on that bootloader build, so
> treat the descriptions below as typical and confirm them against your own
> screen.

Interrupt autoboot by pressing a key during the boot delay and select the
**web recovery** entry from the bootloader menu. Typical builds also expose it
as a command from the U-Boot prompt:

```text
httpd
```

If your build does not show a web recovery entry, it is not available and you
should use [Path C](#7-path-c-u-boot-tftp-and-manual-write-ethernet-required),
[Path D](#8-path-d-serial-uart-transfer-module-only), or
[Path E](#9-path-e-wi-fi-update-module-only-recommended-for-bare-modules).

### 6.3 Network setup

The bootloader's default address is normally:

```text
192.168.1.1
```

1. Connect your PC **directly** to the LAN port, or put both on an isolated
   maintenance switch. Do not rely on DHCP.
2. Give your PC a static address in the same subnet, for example
   `192.168.1.3/24`.
3. Open `http://192.168.1.1/`.

If the console shows a different address, use that one instead. To set the
address for the current session only:

```text
setenv ipaddr 192.168.1.1
httpd
```

### 6.4 Confirm you reached the right device

**A page loading is not proof you are talking to your module.** Any device on
the network could answer. Check on the page:

- the product identifies as Oolite-MT7987A;
- the version string matches the bootloader build you expect;
- the reported boot medium matches your actual storage.

If any of these disagree, stop and re-check cabling and addressing.

### 6.5 The four upload targets

| Target | What it does | Risk |
| --- | --- | --- |
| **Firmware (FIT)** | Writes the sysupgrade FIT into the `firmware` / `fit` region of the active medium | Routine |
| **Initramfs (RAM Boot)** | Boots an image in RAM only; writes nothing to flash | Safe, temporary |
| **Bootloader** | Updates BL2 (ATF) and FIP (U-Boot) | **High** |
| **Full Image** | Rewrites the entire boot medium | **Highest** |

For a routine firmware update choose **Firmware (FIT)** and upload the
sysupgrade `.itb`.

**Initramfs (RAM Boot)** is the safest target and is useful for getting a
running system without touching flash — for example to inspect a device before
deciding what to write. Everything is lost on reboot.

**Bootloader** and **Full Image** are high-risk. A failed or interrupted write
can leave the module unable to reach U-Boot at all, which also removes Web
Recovery as a fallback. Only use them when you have a working serial console
and a recovery path ready, and use **Backup bootloader** first if your
bootloader build offers it.

Factory calibration data is preserved across these operations; none of these
targets writes calibration data, and an empty Factory region stays empty.

### 6.6 After uploading: verify, do not assume

Progress reaching 100%, an HTTP success response, or "upload complete" only
means that phase ended. It is **not** proof the write succeeded.

- Wait for the page to report a definite result, and watch the serial console
  at the same time.
- Independently read back and compare — see the `mtd read` / `hash sha256` /
  `cmp.b` sequence in [Section 7](#7-path-c-u-boot-tftp-and-manual-write-ethernet-required).
- Finish with a full power cycle, not just a reboot.

### 6.7 Limits

- Web Recovery runs **inside U-Boot**. If BL2 or the FIP is damaged and U-Boot
  never starts, it is unavailable — use
  [Path F](#10-path-f-uart-bootrom-recovery-blank-or-bricked).
- If no LAN port is linked, the service cannot serve. Do not treat a missing
  link as a recoverable software error and start reset loops.
- Run it only on an isolated maintenance network, never on an untrusted LAN or
  the public internet.

## 7. Path C: U-Boot TFTP and manual write (Ethernet required)

Useful when you want explicit control over erase, write, and read-back.

```text
setenv ipaddr 192.168.1.1
setenv serverip 192.168.1.2
tftpboot 0x48000000 openwrt-*-squashfs-sysupgrade.itb
echo $filesize
iminfo 0x48000000
```

Confirm `$filesize` matches the file and that `iminfo` parses the FIT before
writing anything.

### SPI-NOR

```text
setexpr erase_size $filesize + 0xffff
setexpr erase_size $erase_size / 0x10000
setexpr erase_size $erase_size * 0x10000
mtd erase firmware 0x0 $erase_size
mtd write firmware 0x48000000 0x0 $filesize
mtd read firmware 0x4a000000 0x0 $filesize
hash sha256 0x4a000000 $filesize
cmp.b 0x48000000 0x4a000000 $filesize
```

Partition names and offsets must be confirmed against your own U-Boot
`mtdparts` output; do not assume they are identical across bootloader builds.

### SPI-NAND

```text
ubi part ubi
ubi write 0x48000000 fit $filesize
ubi read 0x4a000000 fit $filesize
hash sha256 0x4a000000 $filesize
cmp.b 0x48000000 0x4a000000 $filesize
```

`cmp.b` must report every byte identical. A hash mismatch means the write
failed — stop and investigate rather than rebooting.

## 8. Path D: serial UART transfer (module only)

Use this when the module has no Ethernet and you need to reach U-Boot over the
console. Note that a full sysupgrade FIT is around 10 MiB; at 115200 baud a
YMODEM transfer takes a considerable time. For large images prefer
[Path E](#9-path-e-wi-fi-update-module-only-recommended-for-bare-modules).

1. Open the console at 115200 8N1, no flow control, and interrupt autoboot.
2. Start a YMODEM receive in U-Boot:

```text
loady 0x48000000 115200
```

3. Send the `.itb` file from your terminal program using YMODEM.
4. When the transfer completes, verify before writing:

```text
echo $filesize
iminfo 0x48000000
hash sha256 0x48000000 $filesize
```

The length and digest must match the release `SHA256SUMS`. Then write and
read back using the commands in [Section 7](#7-path-c-u-boot-tftp-and-manual-write-ethernet-required).

Higher baud rates such as 921600 may work with a high-quality USB UART
adapter and short wiring, but **115200 is the reliable default**. If a fast
transfer fails, repeat the whole transfer at 115200 rather than retrying
intermittently at high speed.

## 9. Path E: Wi-Fi update (module only, recommended for bare modules)

This is the most practical route for a bare module with no Ethernet port.
The idea is to boot a small RAM system over the serial link, let it bring up
its wireless access point, and then use Wi-Fi as a fast network channel to
write the real firmware to flash.

```text
Serial UART ──► load initramfs-recovery.itb into RAM ──► bootm
                                                          │
                                                          ▼
                                          Wi-Fi AP comes up (open)
                                                          │
                              PC joins the AP ──► SSH / scp ──► sysupgrade
```

### Step 1 — Boot the recovery image from RAM

```text
loady 0x48000000 115200
iminfo 0x48000000
bootm 0x48000000
```

The recovery image runs entirely from RAM; nothing is written to flash by
booting it, and everything is lost on reboot.

### Step 2 — Join the access point

On first boot both radios come up as **open** access points:

```text
Oolite-MT7987A-<MAC4>-2.4G
Oolite-MT7987A-<MAC4>-5G
```

`<MAC4>` is the uppercase last four hex digits of the label MAC address. Your
PC receives an address by DHCP from the device, which is `192.168.1.1` by
default.

### Step 3 — Transfer and install over Wi-Fi

```sh
ssh root@192.168.1.1
```

Then either push the file from your PC:

```sh
scp openwrt-*-squashfs-sysupgrade.itb root@192.168.1.1:/tmp/
```

and install it:

```sh
sha256sum /tmp/openwrt-*-squashfs-sysupgrade.itb
sysupgrade -n /tmp/openwrt-*-squashfs-sysupgrade.itb
```

Or use LuCI in a browser at `http://192.168.1.1/`.

### Notes

- The recovery image runs in RAM, so **you must run `sysupgrade` to make the
  install permanent.** Simply rebooting returns the module to its previous
  state.
- Wireless performance depends entirely on valid Factory calibration data. A
  module with blank or invalid calibration may not produce a usable AP.
- No password is set on first boot. Set a root password immediately once the
  device is on a network you do not fully control.

## 10. Path F: UART BootROM recovery (blank or bricked)

This is the path for a module whose flash is **completely blank** or whose
bootloader is damaged, so that U-Boot never starts. It is also the fallback for
any earlier failure in this guide.

The MediaTek BootROM falls back to a serial download mode when it finds no
valid bootloader. That mode lets a host tool push a temporary BL2 and U-Boot
into RAM. Once a U-Boot prompt exists, flash can be written again — **even on a
module that currently has nothing on it at all.**

### 10.1 What you need

| Item | Needed when | Source |
| --- | --- | --- |
| RAM BL2 (`-p` payload) | always | GainStrong bootloader package |
| RAM recovery FIP (`-f` payload) | always | GainStrong bootloader package |
| Bootloader image for your medium | flash bootloader is blank or damaged | GainStrong bootloader package |
| Factory calibration data | Factory is blank or damaged | **Your own per-device backup** |
| sysupgrade FIT | always | Release download |

> The RAM payloads and the bootloader image must match your module and boot
> medium exactly. Obtain them from GainStrong. Do not substitute payloads from
> another MT798x board.

### 10.2 Load BL2 and U-Boot into RAM

A commonly used open-source host tool is
[`981213/mtk_uartboot`](https://github.com/981213/mtk_uartboot):

```sh
mtk_uartboot -s /dev/ttyUSB0 --aarch64 \
  -p mt7987-ram-bl2.bin \
  -f mt7987-ram-recovery.fip \
  --expected-hw-code 0x7987 \
  --brom-load-baudrate 115200 \
  --bl2-load-baudrate 921600
```

Sequence — the ordering matters:

1. Keep the board powered **off**, and close every other program using the
   serial port.
2. Start the tool first and wait until it reports it is waiting for a
   handshake.
3. Power the board **on**.
4. Confirm the chip code is `0x7987`, and that DDR initialisation and the
   memory test pass.
5. Wait for the FIP transfer to finish and for the RAM U-Boot prompt to appear.
6. Only now open a normal console at 115200 8N1, no flow control.

On a blank part the BootROM is normally already waiting, so no button or strap
is required. If the tool never sees a handshake, check wiring, TX/RX
orientation, common ground, and that the port is not held by another process.

If the high-speed BL2 transfer fails, retry the whole transfer at 115200
rather than retrying intermittently at high speed:

```sh
  --brom-load-baudrate 115200 --bl2-load-baudrate 115200
```

Secure Boot, SLA, or DAA enabled parts will refuse this path.

### 10.3 Restore the bootloader to flash

**UART loading runs in RAM only — it does not repair flash by itself.** A blank
module will still be blank after a reboot unless you now write the bootloader.

Transfer the bootloader image into RAM first, using YMODEM when there is no
Ethernet:

```text
loady 0x48000000 115200
echo $filesize
hash sha256 0x48000000 $filesize
```

Verify length and digest against the bootloader package before writing.

SPI-NOR, writing `0x0`–`0x0e0000`:

```text
mtd erase bootloader 0x0 0xe0000
mtd write bootloader 0x48000000 0x0 0xe0000
mtd read bootloader 0x4a000000 0x0 0xe0000
hash sha256 0x4a000000 0xe0000
cmp.b 0x48000000 0x4a000000 0xe0000
```

SPI-NAND, writing the raw bootloader window `0x0`–`0x200000`:

```text
mtd erase bootloader 0x0 0x200000
mtd write bootloader 0x48000000 0x0 0x200000
mtd read bootloader 0x4a000000 0x0 0x200000
hash sha256 0x4a000000 0x200000
cmp.b 0x48000000 0x4a000000 0x200000
```

SD and eMMC use the GPT `fip` and `bl2` partitions; follow the offsets given in
the bootloader package.

Partition names come from your bootloader's own `mtdparts` output. Confirm them
with `mtd list` before writing; do not assume names are identical across
bootloader builds.

### 10.4 Restore Factory calibration data

> **This is the step most often forgotten, and it cannot be corrected later.**
> If the Factory region is blank, WiFi will not work: device-specific
> calibration cannot be regenerated or substituted.

- If you saved a backup of this module's `Factory` partition, restore it now to
  the same region: NOR `0x0f0000` (64 KiB), the NAND `Factory` UBI volume, or
  the GPT `Factory` partition.
- If you have **no backup**, contact GainStrong before proceeding. Do not copy
  Factory data from another module, and do not fill the region with `0xFF` or
  zeros — both produce a radio that appears present but is uncalibrated and
  illegal to operate.
- Restoring Factory is entirely your own step: nothing in this guide creates or
  initialises calibration data.

### 10.5 Restore the firmware

With a bootloader on flash, continue with the normal firmware write:

- No Ethernet: [Path D](#8-path-d-serial-uart-transfer-module-only) or
  [Path E](#9-path-e-wi-fi-update-module-only-recommended-for-bare-modules).
- Ethernet available: [Path B](#6-path-b-u-boot-web-recovery-ethernet-required)
  or [Path C](#7-path-c-u-boot-tftp-and-manual-write-ethernet-required).

You may also write the firmware while still running the RAM U-Boot, then do a
full power cycle.

### 10.6 Cold-boot verification

A blank-flash recovery is not complete until the module boots on its own:

1. Remove power completely, then reapply it.
2. Confirm the bootloader now comes from on-board flash, not from UART.
3. Confirm `Boot media:` matches your storage.
4. Confirm the FIT hash check passes and OpenWrt starts.
5. Confirm `board_name` is `gainstrong,oolite-mt7987a`.
6. Confirm WiFi only after valid Factory data is confirmed present.

Until step 2 passes, the module is still dependent on the UART tool.

## 11. Path G: external programmer (before assembly)

For blank flash chips before SMT assembly, an external SPI programmer is the
fastest route. It needs a complete flash image for your specific module and
boot medium, which you should obtain from GainStrong.

Basic discipline:

1. Read the chip twice and confirm both reads are identical before erasing.
2. Identify the exact part number, package, and voltage from the chip marking.
3. Write the image and read back for comparison.
4. Never let the programmer pad a partial file with `0xFF` across the whole
   device; that destroys existing environment, Factory, and system data.

## 12. Verification and acceptance

After any write, confirm each of the following before declaring success:

1. Read-back digest matches the source file, and a byte comparison reports all
   bytes identical.
2. A full power cycle — not just `reboot` — reaches U-Boot from on-board flash.
3. `Boot media:` matches your actual storage.
4. The FIT hash check passes and the expected OpenWrt version boots.
5. `board_name` is `gainstrong,oolite-mt7987a`.
6. `/proc/mtd`, `ubinfo -a`, or the GPT table matches the layout in
   [Section 3](#3-memory-layout-by-boot-medium).
7. `fw_printenv` reads the same environment U-Boot uses. A `Bad CRC` result
   must be recorded as a problem, not treated as a successful environment
   write.
8. WiFi: the endpoint enumerates and both bands come up — **only after valid
   Factory calibration data is present.**

A single successful boot does not explain an earlier failure to boot. If
cold-start behaviour is intermittent, keep the failing console log and
investigate boot strap sampling, supply rails, and flash signalling.

## 13. Risks and limitations

- Writing a bootloader is the highest-risk operation. A failed or interrupted
  bootloader write leaves Web Recovery unavailable too, and recovery then
  requires UART or a programmer.
- Do not power off, reset, or disconnect during an erase or write.
- Do not treat "upload complete", "progress 100%", or an HTTP 200 response as
  proof of success. Only an independent read-back plus a cold boot is proof.
- Never overwrite the `Factory` partition. It holds device-specific
  calibration and the MAC address, and it cannot be regenerated from this
  branch.
- Installing a system image does not by itself constitute RF calibration,
  functional acceptance, or production release qualification.
