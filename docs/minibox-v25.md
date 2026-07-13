# GainStrong Minibox V2.5 Support Notes

This branch adds OpenWrt 25.12 support for GainStrong Minibox V2.5 on the
ramips/mt76x8 target.

## Hardware Summary

The board support is based on hardware review and earlier internal OpenWrt
support, then updated to the OpenWrt 25.12 device-tree and board defaults
style.

| Item | OpenWrt setting |
| --- | --- |
| Target | OpenWrt `ramips/mt76x8` |
| Compatible | `gainstrong,minibox-v2.5` |
| Model | `GainStrong Minibox V2.5` |
| Flash profile | 16 MiB SPI NOR image profile |
| Flash layout | `u-boot` at `0x0`, `u-boot-env` at `0x30000`, `factory` at `0x40000`, `firmware` at `0x50000` |
| Firmware partition | DTS size is `0x0`, so it consumes the remaining flash after the fixed partitions |
| Ethernet | Single Ethernet port configured as LAN; no WAN interface is created |
| MAC source | Label MAC from factory offset `0x4`; LAN MAC is label MAC plus 1 |
| 2.4 GHz WiFi | SoC radio, factory EEPROM at factory offset `0x0` |
| 5 GHz WiFi | PCIe radio, factory EEPROM at factory offset `0x8000` |
| USB | USB 2.0 host with storage support |
| I2C | I2C bus enabled; charger, fuel-gauge, and secure-element addresses are described in DTS |
| Status LED | Green power LED on GPIO39 |
| Buttons | Reset and power GPIO keys |

The green power LED is configured as the OpenWrt system LED. It turns on when
the kernel registers the GPIO LED, blinks during OpenWrt boot and upgrade, then
stays on after the system reaches the running state.

## Default Network Behavior

The default Ethernet mapping is a single LAN interface:

```text
lan: eth0
```

The default LAN IP address follows OpenWrt defaults:

```text
192.168.1.1
```

WiFi is enabled by default. The generated AP SSIDs use the product name and the
last four uppercase hexadecimal characters of the factory label MAC:

```text
Minibox-V2.5-XXXX-2G
Minibox-V2.5-XXXX-5G
```

The default APs are open (`encryption=none`). The 5 GHz radio uses channel 36 by
default. No WiFi country code is configured by default.

### WiFi Site Survey

The MT7628 2.4 GHz radio uses the `mt7603` software-scan path. Elwin Huang
reported and analyzed the regression in upstream
[mt76 issue 973](https://github.com/openwrt/mt76/issues/973). Affected mt76
versions can spend four to five seconds away from the AP operating channel
during a site survey. That interruption can make an associated client
disconnect when `iw`, `iwinfo`, or the LuCI scan action requests a scan.

The regression follows mt76 commit `c03d84c0d018` (`wifi: mt76: mt7603:
improve stuck beacon handling`). That commit moved beacon queue cleanup to the
beginning of the pre-TBTT tasklet and changed the empty-CAB path from a shared
cleanup exit to an immediate return. After a new beacon is queued, the early
return therefore skips the second cleanup pass needed while software scan
changes channels.

This branch applies the solution proposed in issue 973: clean completed MT7603
beacon descriptors immediately before the empty-CAB return. It restores the
previous cleanup timing without reverting the stuck-beacon recovery. At the
time this branch was validated, issue 973 remained open and mt76 master did not
contain the corresponding fix, so the change is carried as a downstream patch
with the original author and source recorded in its patch header.

Use the host-side regression script with SSH routed over Ethernet and ping
forced through a WiFi client already connected to the AP:

```sh
scripts/test-minibox-v25-wifi-scan.sh \
  --client-iface wlp131s0 \
  --radio-iface phy0-ap0 \
  --iterations 5
```

The script does not create a WiFi connection or change routes. It records scan
duration, packet loss, maximum round-trip time, client disconnects, and new mt76
kernel errors under `logs/`.

Reference validation with an associated 2.4 GHz client produced these results:

| Test | Scan duration | Packet loss | Maximum latency | Disconnects or mt76 errors |
| --- | --- | --- | --- | --- |
| Unpatched single scan | 4.59 s | 10.00% | 4474 ms | 0 |
| Patched 10-scan test | 1.20-1.29 s | 0.83-5.00% per scan | 1477 ms | 0 |
| Patched 30-minute test | 1.19-1.30 s over 60 scans | 2.06% overall | 1428 ms | 0 |

The 5 GHz radio remains on its firmware-assisted scan path. A three-scan
control test completed in 3.52-3.56 seconds without disconnecting the client or
adding mt76 errors.

Cellular modem support is not part of the default product configuration. No WAN
interface is created by default.

## VPN and Web Configuration

The product configuration includes LuCI support for WireGuard, OpenVPN, policy
based routing, and web-invoked shell commands:

- WireGuard is provided through `luci-proto-wireguard`, `rpcd-mod-wireguard`,
  and `wireguard-tools`.
- OpenVPN uses the OpenSSL variant and includes `openvpn-easy-rsa` for local
  PKI and certificate generation.
- Policy based routing is provided through `luci-app-pbr`.
- Custom web commands are provided through `luci-app-commands`.

The firmware does not create real VPN keys, certificates, endpoints, tunnels,
or policies by default.

## USB, PCIe, Battery, and I2C Tools

The product configuration includes local USB storage support. It provides
`usbutils`, block-device mount support, UAS-capable USB mass storage, and common
filesystem support for ext4, FAT, exFAT, and NTFS3. Filesystem maintenance
tools are included for ext4, FAT, and exFAT.

PCI inspection uses `pciutils`. I2C inspection uses `i2c-tools`.

The charger, fuel-gauge, and secure-element devices are modeled in DTS and
visible through I2C tooling. The firmware includes the BQ27xxx I2C fuel-gauge
driver and the TI `bqtool` utility for service work.

The secure element is expected at I2C address `0x64`. The Linux
`atmel-sha204a` driver only exposes the chip after the device zones are locked;
unlocked service samples can still be detected on the I2C bus but may be
rejected by the kernel crypto driver.

The charger register defaults are described in DTS under `charger@4b` and
applied on every boot by `/usr/sbin/minibox-v25-charge-set`, because the charger
does not keep these settings after power loss. After a cold power-up the charger
starts with conservative input and charge-current limits. If OpenWrt leaves those
defaults in place until the late boot sequence, the board can reboot when the
Ethernet bridge and WiFi radios start drawing more current.

The charger setup service therefore runs at `START=18`, before the normal
network and WiFi services. It programs the input voltage limit, charge current,
input current limit, and disables the charger watchdog early enough that the
board is not left running on the default current limit during the network and
WiFi power-up window. The source tree only carries the init script; OpenWrt
generates the matching `/etc/rc.d/S18minibox-v25-charge` symlink from `START=18`
while building the root filesystem.

Battery capacity and alert thresholds are stored in the packaged BQFS profile.
The upstream BQ27xxx driver does not provide a data-memory map for the BQ27546
profile used here, so the firmware does not rely on a DTS `simple-battery` node
for capacity programming. Use the maintenance command only when the fuel-gauge
profile needs to be installed or repaired:

```sh
minibox-v25-bq27546-update
```

The production fuel-gauge profile sets the design capacity to 3400 mAh, design
energy to 12580 mWh, and SOC1 thresholds to 340/408 mAh.

Network file sharing services are not enabled by default.

## Bootloader Maintenance

The `u-boot` partition remains read-only in DTS. The product image includes
`kmod-mtd-rw` so maintenance builds can explicitly unlock MTD partitions when a
bootloader update is required.

Load the module only for controlled service work:

```sh
insmod mtd-rw i_want_a_brick=1
```

After the module is loaded, the normal `mtd` utility can write the bootloader
partition. Reboot after the service operation so the temporary write override is
cleared.

## Build

Run the one-click build helper from the repository root:

```sh
./build-minibox-v25.sh
```

Useful options:

```sh
./build-minibox-v25.sh --skip-feeds
./build-minibox-v25.sh --log logs/my-minibox-v25-build.log
./build-minibox-v25.sh --no-alias
```

The script copies `Minibox-V2.5.config` to `.config`, injects the repository
version from `scripts/getver.sh`, runs `make defconfig`, and builds with all
local CPU cores. The version code uses the current commit timestamp and short
hash, for example `YYYYMMDD-HHMM-XXXXXXX`.

The sysupgrade image is generated under:

```text
bin/targets/ramips/mt76x8/
```

OpenWrt still emits the canonical target/profile filename, for example:

```text
gainstrong-minibox-v2.5-25.12.4-YYYYMMDD-HHMM-XXXXXXX-ramips-mt76x8-gainstrong_minibox-v25-squashfs-sysupgrade.bin
```

The alias helper creates this compact versioned sysupgrade symlink:

```text
minibox-v25-sysupgrade-YYYYMMDD-HHMM-XXXXXXX.bin
```

The build helper preserves older Minibox V2.5 artifacts. New builds add the
current canonical image and compact alias without deleting previous release
files from the target directory.

If the worktree was dirty during the build, the version code and alias include
the `-dirty` suffix.

## Verification Checklist

Before publishing or flashing a release build, verify:

- `make defconfig` accepts `CONFIG_TARGET_ramips_mt76x8_DEVICE_gainstrong_minibox-v25=y`.
- The generated image filename contains the explicit version code.
- The sysupgrade image is under the configured 16 MiB profile limit.
- The board boots and reports `GainStrong Minibox V2.5` in `/tmp/sysinfo/model`.
- `/etc/board.json` contains the Minibox V2.5 wireless defaults.
- The default SSIDs start with `Minibox-V2.5-` and end with the last four
  uppercase hexadecimal characters of the label MAC.
- The 2.4 GHz and 5 GHz APs are both enabled by default.
- The 5 GHz AP uses channel 36.
- A 2.4 GHz site survey completes without disconnecting an associated client or
  leaving the AP unable to transmit beacons.
- The only Ethernet port comes up as LAN, and no WAN or WAN6 interface is
  generated.
- The GPIO keys expose reset and power only.
- The green power LED turns on during kernel startup, blinks during OpenWrt
  boot, and stays on after startup.
- The boot-time charger setup completes before Ethernet and WiFi startup, so the
  board does not reboot when network load rises during boot.
- The charger setup leaves register `0x00` at `0x60`, register `0x01` at
  `0x0a`, register `0x05` at `0xa0`, and register `0x08` at `0x85`.
- The charger setup service starts before `wpad` and `network`; the generated
  rootfs contains `/etc/rc.d/S18minibox-v25-charge`.
- The secure element is visible at I2C address `0x64`.
- The packaged battery directory contains only the BQ27546 BQFS profile.
- The fuel gauge reports a 3400 mAh design capacity after the BQ27546 BQFS
  profile has been installed.
- The image manifest contains WireGuard, OpenVPN, EasyRSA, PBR, and LuCI
  command support.
- The image manifest contains USB storage, `usbutils`, block mount, PCI, I2C
  tooling, `bqtool`, the BQ27xxx fuel-gauge driver, and `kmod-mtd-rw`.
