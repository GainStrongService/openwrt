# GainStrong Minibox V2.0 Support Notes

This branch adds OpenWrt 25.12 support for GainStrong Minibox V2.0 on the
ramips/mt76x8 target.

## Hardware Summary

The board support is based on the hardware review and follows the OpenWrt
25.12 device-tree and board-defaults style.

| Item | OpenWrt setting |
| --- | --- |
| Target | OpenWrt `ramips/mt76x8` |
| Compatible | `gainstrong,minibox-v2` |
| Model | `GainStrong Minibox V2.0` |
| Flash options | 16 MiB, 32 MiB, or 64 MiB SPI NOR |
| Flash layout | `u-boot` at `0x0`, `u-boot-env` at `0x30000`, `factory` at `0x40000`, `firmware` at `0x50000` |
| Firmware partition | DTS size is `0x0`, so it consumes the remaining flash after the fixed partitions and automatically adapts to all supported flash capacities |
| Ethernet | MT76x8 switch port 0 is LAN, port 1 is WAN |
| MAC source | Label MAC from factory offset `0x4`; WAN MAC is label MAC plus 2 |
| WiFi calibration | Factory EEPROM from factory offset `0x0` |
| Status LED | RGB common-anode LED, software controlled as active-low GPIO LEDs |
| Reset button | GPIO38, active low |

The current hardware uses a three-color status LED. The common pin is tied to
3.3 V, so each color channel turns on when its SoC GPIO output is driven low.
The device tree follows the board LED color net names and exposes all three
channels:

| LED channel | SoC function | OpenWrt GPIO |
| --- | --- | --- |
| Red | `EPHY_LED1_N_JTDI` | GPIO42 |
| Green | `EPHY_LED0_N_JTDO` | GPIO43 |
| Blue | `WLED_N` | GPIO44 |

OpenWrt uses the blue channel for normal boot and running status. It turns on
when the kernel registers the GPIO LED, blinks during OpenWrt boot, then stays
on after the system reaches the running state. The red channel is reserved for
failsafe and upgrade status. The green channel is exposed for user
configuration or future product behavior.

The reset switch is connected to the SoC `WDT_RST_N` pin, which is muxed as
GPIO38 in OpenWrt and registered as an active-low `KEY_RESTART` input. The
`wdt` pin group must stay in GPIO mode for this button to work.

## Default Network Behavior

The default switch mapping is:

```text
switch0: 0:lan 1:wan 6@eth0
```

The physical Ethernet port on the Type-C power connector side is the LAN port
and serves the default `192.168.1.1` management address. The Ethernet port on
the reset-button side is the WAN port and uses DHCP by default.

WiFi is enabled by default through the board defaults in `/etc/board.json`.
The generated AP SSID uses the product name and the last four uppercase
hexadecimal characters of the factory label MAC:

```text
Minibox-V2-XXXX
```

The default AP is open (`encryption=none`). Cellular modem support is not part
of the default product configuration.

## VPN and Web Configuration

The product configuration includes LuCI support for WireGuard, OpenVPN, policy
based routing, and web-invoked shell commands:

- WireGuard is provided through `luci-proto-wireguard`.
- OpenVPN uses the OpenSSL variant and includes `openvpn-easy-rsa` for local
  PKI and certificate generation.
- Policy based routing is provided through `luci-app-pbr`.
- Custom web commands are provided through `luci-app-commands`.

Users configure tunnels, routing policies, certificates, and optional web
commands explicitly through LuCI, UCI, or the command line.

## Maintenance Package

The product configuration includes `kmod-mtd-rw` for explicit maintenance
access to read-only MTD partitions when service work requires it. It is part of
the customer firmware build profile, not the hardware image profile.

## USB Storage

The product configuration includes local USB storage support. It provides
`usbutils`, block-device mount support, UAS-capable USB mass storage, and common
filesystem support for ext4, FAT, exFAT, and NTFS3. Filesystem maintenance tools
are included for ext4, FAT, and exFAT.

Network file sharing services are not enabled by default.

## Build

Run the one-click build helper from the repository root:

```sh
./build-minibox-v2.sh
```

Useful options:

```sh
./build-minibox-v2.sh --skip-feeds
./build-minibox-v2.sh --log logs/my-minibox-v2-build.log
```

The script copies `Minibox-V2.0.config` to `.config`, injects the repository
version from `scripts/getver.sh`, runs `make defconfig`, and builds with all
local CPU cores. The version code uses the current commit timestamp and short
hash, for example `YYYYMMDD-HHMM-XXXXXXX`.

The sysupgrade image is generated under:

```text
bin/targets/ramips/mt76x8/
```

OpenWrt still emits the canonical target/profile filename, for example:

```text
gainstrong-minibox-v2.0-25.12.5-YYYYMMDD-HHMM-XXXXXXX-ramips-mt76x8-gainstrong_minibox-v2-squashfs-sysupgrade.bin
```

The build helper preserves older Minibox V2 artifacts. New builds add the
current canonical image without deleting previous release files from the target
directory.

If the worktree was dirty during the build, the version code includes the
`-dirty` suffix.

## Verification Checklist

Before publishing or flashing a release build, verify:

- `make defconfig` accepts `CONFIG_TARGET_ramips_mt76x8_DEVICE_gainstrong_minibox-v2=y`.
- The generated image filename contains the explicit version code.
- The sysupgrade image fits within the 16 MiB minimum supported flash capacity.
- The firmware partition expands automatically on 16 MiB, 32 MiB, and 64 MiB
  flash variants.
- The board boots and reports `GainStrong Minibox V2.0` in `/tmp/sysinfo/model`.
- `/etc/board.json` contains the Minibox V2 wireless defaults.
- The default SSID starts with `Minibox-V2-` and ends with the last four
  uppercase hexadecimal characters of the label MAC.
- LAN is on switch port 0 and WAN is on switch port 1.
- The blue status LED turns on during kernel startup, blinks during OpenWrt
  boot, and stays on after startup.
- The red, green, and blue LED channels are present under `/sys/class/leds/`
  and are software controllable.
- The reset switch is reported as an active-low Linux `KEY_RESTART` input on
  GPIO38.
- The image manifest contains WireGuard, OpenVPN, EasyRSA, PBR, and LuCI
  command support.
- The image manifest contains USB storage, `usbutils`, block mount, and common
  filesystem support.
