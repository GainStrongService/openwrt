# GainStrong Oolite-MT7987A OpenWrt Support

## Scope

This branch provides Linux and OpenWrt firmware support for GainStrong
Oolite-MT7987A on OpenWrt 25.12. It is intentionally firmware-only: a
compatible bootloader must already be installed and must select the
device-tree overlay for the active boot medium.

The branch does not add or emit ATF, U-Boot, Web Recovery, bootloader images,
full-flash or disk images, default calibration data, production-test tools or
bring-up helpers.

## Hardware

- MediaTek MT7987A with DDR4
- MT7987 internal 2.5GbE PHY used as LAN
- MT7990AN and MT7976C radio design exposed as PCI device `14c3:7993`
- USB 3.0 host
- SPI-NOR, SPI-NAND, SD and eMMC boot variants
- 8-bit eMMC at up to 48 MHz

The PCIe WiFi reset uses the standard MT7987 PCIe pinmux and controller reset
flow. The device profile includes the MT7987 Ethernet PHY and MT7990 firmware
required by the installed endpoint.

## OpenWrt Integration

The board uses one device profile and seven device-tree overlays:

| Overlay | Firmware storage |
| --- | --- |
| `mt7987a-gainstrong-oolite-mt7987a-nor` | FIT in the SPI-NOR `firmware` partition at `0x100000` |
| `mt7987a-gainstrong-oolite-mt7987a-nand` | FIT in the `fit` UBI volume; UBI starts at `0x300000` |
| `mt7987a-gainstrong-oolite-mt7987a-sd` | FIT in the existing GPT `firmware` partition |
| `mt7987a-gainstrong-oolite-mt7987a-emmc` | FIT in the existing GPT `firmware` partition |
| `mt7987a-gainstrong-oolite-mt7987a-nor-emmc` | SPI-NOR root with eMMC attached storage |
| `mt7987a-gainstrong-oolite-mt7987a-nor-sd` | SPI-NOR root with SD attached storage |
| `mt7987a-gainstrong-oolite-mt7987a-nor-nand` | SPI-NOR root with SPI-NAND attached storage |

The generated FIT contains the base DTB and all seven overlays. The same
firmware artifact is used for every boot medium, and the pre-installed
bootloader selects the active overlay.

The three `nor-*` attached-storage overlays keep the kernel, root filesystem,
bootloader environment and calibration data on SPI-NOR. The secondary storage
device is exposed without selecting it as rootdisk or formatting it.

The SPI-NOR bootloader ends at `0x0e0000`; U-Boot environment and Factory
occupy `0x0e0000` and `0x0f0000`, and firmware starts at `0x100000`. The
SPI-NAND bootloader occupies the first `0x200000`, followed by a `0x100000`
reserved window and UBI at `0x300000`. Bootloader, reserved and NOR Factory
regions are read-only in Linux.

Existing SD and eMMC GPT layouts place `bl2` before `0x100000`, `fip` from
`0x100000`, Factory at `0x300000`, U-Boot environment at `0x340000`, and
firmware at `0x380000`. This branch updates only the existing firmware
partition and does not generate a bootable whole-disk image.

## Calibration and Defaults

WiFi calibration is read from the `Factory` partition or UBI volume selected
by the active overlay. The MT76 nvmem cell uses offset `0x0` and size
`0x1e00`.

This branch does not add a board-specific EEPROM image and never writes
fallback calibration data to an empty Factory region. The upstream MT76
firmware packages include their standard firmware and fallback assets; those
files are not device-specific Factory calibration. A production device must
contain valid device-specific calibration data before WiFi is considered
supported.

Runtime defaults are:

- the internal 2.5GbE interface is LAN and is named `lan`;
- the base module does not define a WAN interface;
- regulatory country is `CN`;
- both radios are enabled as open access points on first boot;
- SSIDs are `Oolite-MT7987A-<MAC4>-2.4G` and
  `Oolite-MT7987A-<MAC4>-5G`;
- `<MAC4>` is the uppercase final four hexadecimal digits of the label MAC,
  with a band-only fallback when no valid MAC is available;
- later user wireless changes are not overwritten.

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

The script uses `Oolite-MT7987A.config`, synchronizes feeds through the
OpenWrt 25.12 feeds interface, preserves existing artifacts, and writes build
output to `logs/`. It rejects a local `feeds.conf` override and refuses to
overwrite an existing log or current-version artifact.

The expected device artifacts are:

- `*gainstrong_oolite-mt7987a-squashfs-sysupgrade.itb`
- `*gainstrong_oolite-mt7987a-initramfs-recovery.itb`

The sysupgrade FIT is limited to 31,232 KiB. The build fails if the current
version produces a preloader, U-Boot, bootloader, whole-disk, Factory or
full-image artifact, or if its manifest contains excluded bootloader,
default-calibration or bring-up packages. It also checks that all seven
overlays are present in the FIT.

## Upgrade

`sysupgrade` writes only the firmware storage selected by the active overlay.
It does not update bootloader, U-Boot environment, Factory or reserved data.
Use `sysupgrade -n` when settings from an older or unrelated image must not be
retained.

## Validation Checklist

1. Run `git diff --check` and inspect the public commit sequence.
2. Run `make defconfig` through `./build.sh` and complete a parallel build.
3. Confirm the manifest contains `kmod-mtd-rw` and none of the excluded
   package families.
4. Inspect the FIT with `dumpimage -l` and confirm the base DTB, all seven
   overlays, kernel and rootfs are present.
5. Confirm image metadata includes `gainstrong,oolite-mt7987a` exactly once.
6. Confirm the sysupgrade FIT is no larger than 31,232 KiB.
7. On an authorized calibrated device, confirm the active storage layout,
   2.5GbE LAN, PCIe WiFi, both radio bands and `sysupgrade` behavior.

An earlier internal release provided a hardware reference for SPI-NOR plus
eMMC operation at 8-bit and 48 MHz. The current reorganization has passed the
firmware-only build and static gates, but its current hardware sample did not
produce a BROM or boot log during the new validation attempt. The earlier
reference therefore does not count as current-branch hardware acceptance.
Other media require their own current-branch hardware evidence.

Hardware validation must use artifacts built from the reviewed branch. Older
internal build logs are not evidence for a rebuilt public commit series.
