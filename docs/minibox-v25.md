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
applied on every boot by `/usr/sbin/minibox-v25-charge-set`, because the
charger does not keep these settings after power loss. The startup service
programs the input voltage limit, charge current, input current limit, and
disables the charger watchdog.

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
- The only Ethernet port comes up as LAN, and no WAN or WAN6 interface is
  generated.
- The GPIO keys expose reset and power only.
- The green power LED turns on during kernel startup, blinks during OpenWrt
  boot, and stays on after startup.
- The boot-time charger setup leaves register `0x00` at `0x60`, register `0x01`
  at `0x0a`, register `0x05` at `0xa0`, and register `0x08` at `0x85`.
- The secure element is visible at I2C address `0x64`.
- The packaged battery directory contains only the BQ27546 BQFS profile.
- The fuel gauge reports a 3400 mAh design capacity after the BQ27546 BQFS
  profile has been installed.
- The image manifest contains WireGuard, OpenVPN, EasyRSA, PBR, and LuCI
  command support.
- The image manifest contains USB storage, `usbutils`, block mount, PCI, I2C
  tooling, `bqtool`, the BQ27xxx fuel-gauge driver, and `kmod-mtd-rw`.
