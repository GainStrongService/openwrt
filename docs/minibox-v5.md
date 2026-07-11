# GainStrong Minibox V5 OpenWrt Support

## Scope

This branch provides Linux and OpenWrt firmware support for GainStrong
Minibox V5 on OpenWrt 25.12. It is intentionally firmware-only: a compatible
bootloader must already be installed and must select the device-tree overlay
for the active boot medium.

The branch does not add or emit ATF, U-Boot, Web Recovery, bootloader images,
full-flash images, Bluetooth components, cellular-modem support, calibration
firmware or production-test tools.

## Hardware

- MediaTek MT7981B with 512 MiB DDR4
- Dual-band MT7981 WiFi with calibration data in an I2C EEPROM
- RTL8221B 2.5GbE WAN and MT7981 internal Gigabit LAN
- PCA9557 GPIO expander
- USB 3.0 hub
- SPI-NOR, SPI-NAND, SD and eMMC boot variants

## OpenWrt Integration

The board uses one device profile and four device-tree overlays:

| Overlay | Firmware storage |
| --- | --- |
| `mt7981b-gainstrong-minibox-v5-nor` | FIT in the SPI-NOR `firmware` partition at `0x100000` |
| `mt7981b-gainstrong-minibox-v5-nand` | FIT in the `fit` UBI volume; UBI starts at `0x200000` |
| `mt7981b-gainstrong-minibox-v5-sd` | FIT in the existing GPT `firmware` partition |
| `mt7981b-gainstrong-minibox-v5-emmc` | FIT in the existing GPT `firmware` partition |

The generated FIT contains the base DTB and all four overlays. The same
firmware artifact is used for every boot medium, and the pre-installed
bootloader selects the active overlay.

The NAND boot area from `0x000000` through `0x17ffff` and the reserved window
from `0x1a0000` through `0x1fffff` are read-only in Linux. This branch does not
provide any path for updating BL2, FIP or a whole flash device.

## Runtime Defaults

- `eth1` is LAN and `eth0` is the RTL8221B WAN port.
- Ethernet MAC addresses and WiFi calibration are read from the I2C EEPROM.
- WiFi is enabled on first boot.
- Default SSIDs are `Minibox-V5_<suffix>_2G` and
  `Minibox-V5_<suffix>_5G`.
- `<suffix>` is the final four uppercase hexadecimal digits of the base MAC
  stored at EEPROM offset `0x4`.
- The SSID suffix is never derived from adjusted LAN, WAN or PHY addresses.

The EEPROM may not be available during the early board-default phase. A
board-specific `uci-defaults` script retries after kernel modules are loaded,
updates `board.json` and the generated wireless configuration, and remains in
place when the EEPROM cannot be read.

## Build

Run the repository build entry point:

```sh
./build.sh
```

Optional arguments:

```text
--log <file>     Select a new build log path
--skip-feeds     Reuse already installed feeds
--jobs <count>   Select parallel build jobs
```

The script uses `Minibox-V5.0.config`, synchronizes feeds through the OpenWrt
25.12 feeds interface, preserves existing artifacts, and writes build output
to `logs/`. It refuses to overwrite an existing log or current-version
artifact.

The expected device artifacts are:

- `*gainstrong_minibox-v5-squashfs-sysupgrade.itb`
- `*gainstrong_minibox-v5-initramfs-recovery.itb`

The build fails if the current version produces a preloader, U-Boot,
bootloader or full-image artifact, or if its manifest contains excluded
bootloader, Bluetooth or cellular-modem packages.

## Upgrade

`sysupgrade` writes only the firmware storage selected by the active overlay.
It does not update bootloader partitions, U-Boot environment data or reserved
calibration-compatible space. Use `sysupgrade -n` when settings from an older
or unrelated image must not be retained.

## Validation Checklist

1. Run `git diff --check` and inspect the public commit sequence.
2. Run `make defconfig` through `./build.sh` and complete a parallel build.
3. Confirm the manifest contains `kmod-mtd-rw` and none of the excluded
   package families.
4. Inspect the FIT with `dumpimage -l` and confirm the base DTB, all four
   overlays, kernel and rootfs are present.
5. Confirm image metadata includes `gainstrong,minibox-v5`.
6. On an authorized test device, confirm the active storage layout, LAN/WAN,
   EEPROM-backed MAC addresses, both WiFi radios and `sysupgrade` behavior.

Hardware validation must use artifacts built from the reviewed branch. Older
internal build logs are not evidence for a rebuilt public commit series.
