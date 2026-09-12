# GainStrong GS-R3000N-H4 OpenWrt 25.12 SDK

This repository contains the public OpenWrt adaptation for the GainStrong
GS-R3000N-H4. It provides the board definition, NAND image recipes, a small
configuration seed, and a reproducible entry point for building firmware and
the OpenWrt SDK.

The public tree does not contain board-specific boot-chain binaries, private
calibration data, original image files, or internal recovery material. Use a
bootloader that is already matched to the board and its NAND layout.

## Start here

Read the official OpenWrt build-system documentation for host setup and build
troubleshooting:

<https://openwrt.org/docs/guide-developer/build-system/install-buildsystem>

From the repository root, run one command:

```sh
./build.sh
```

The entry point loads `GS-R3000N-H4.config`, updates and installs the pinned
feeds, runs `make defconfig`, builds the firmware, and then builds the SDK.
The generated `.config` is temporary and is not a customer configuration
source. The build uses `-j$(nproc)` so the native make jobs follow the current
available processing units.

For a single output type, use one of these optional modes:

```sh
./build.sh --firmware-only
./build.sh --sdk-only
```

The SDK is built with `make target/sdk/compile` because the ordinary OpenWrt
firmware target does not create an SDK unless the SDK target is requested.
Build output is written by OpenWrt to:

```text
bin/targets/mediatek/filogic/
```

If a host prerequisite, feed, toolchain, or permission error occurs, follow
the official OpenWrt documentation above and retain the native command output.
This project entry point does not contain host-specific repair procedures.

## Configuration and versioning

`GS-R3000N-H4.config` is the versioned configuration seed. It contains only
the target selection, required image options, product metadata, and direct
package choices. OpenWrt resolves base packages and dependencies during
`make defconfig`; do not commit the generated `.config`.

The source tree fixes the following release inputs:

- OpenWrt 25.12 baseline: `7722054025462cbc4cc6225cfe49ea0ad409b302`
- OpenWrt release metadata: `25.12.5`
- Public feed revisions: `feeds.conf.default`
- Product distribution: `GainStrong`
- Product model: `GS-R3000N-H4`

The OpenWrt revision is obtained from the Git source through
`scripts/getver.sh`. A dirty suffix indicates that source changes are present;
use a clean commit for a release. The recommended topic order is board
support and image layout, version and build metadata, configuration and build
entry point, then documentation.

## Target and NAND layout

The target is an MT7981B system with 256 MiB DDR3 and 128 MiB SPI-NAND. The
logical image window remains 64 MiB because that is the compatible UBI region;
it does not describe the physical NAND capacity. The image recipe therefore
keeps:

```make
IMAGE_SIZE := 65536k
```

The fixed NAND layout is:

| Region | Start | End | Size | Rule |
| --- | ---: | ---: | ---: | --- |
| `bl2` | `0x000000` | `0x100000` | 1 MiB | Existing boot chain; not a routine firmware target |
| `u-boot-env` | `0x100000` | `0x180000` | 512 KiB | Existing bootloader environment |
| `Factory` | `0x180000` | `0x380000` | 2 MiB | Device data and calibration; preserve it |
| `FIP` | `0x380000` | `0x580000` | 2 MiB | Existing boot chain; not a routine firmware target |
| `ubi` | `0x580000` | `0x4580000` | 64 MiB | Kernel and root filesystem |

NAND parameters are 2048-byte pages, 128 KiB erase blocks, and 64-byte OOB.
NMBM and UBI manage bad blocks and erase metadata. This is not a contiguous
raw-byte image layout.

The board definition reads the base MAC and wireless calibration data from the
`Factory` partition. No production MAC value is embedded in the source.

## Generated files

Keep files from the same build together. The usual roles are:

| File | Use | Limitation |
| --- | --- | --- |
| `*squashfs-sysupgrade.bin` | Upgrade from a running matching OpenWrt system | Not a raw NAND dump |
| `*squashfs-factory.bin` | Initial installation when the matched bootloader explicitly requests this payload | Not a full flash image and not a boot-chain file |
| `*initramfs-kernel.bin` | Temporary RAM boot or recovery | Does not persist after reset |
| `*-sdk-*.tar.zst` | Package and firmware development | Not a board flashing image |
| `*.manifest`, `*.buildinfo`, checksum files | Build and package provenance | Must remain paired with the same build |

Never substitute one file type for another. In particular, do not place an
SDK archive, a RAM image, a boot-chain file, or a raw NAND dump in a firmware
update field.

## Serial and TFTP recovery

The complete English procedure is in
[`docs/GS-R3000N-H4-serial-tftp-flashing-guide.md`](docs/GS-R3000N-H4-serial-tftp-flashing-guide.md).

The basic recovery roles are:

```text
Console:       115200 baud, 8 data bits, no parity, 1 stop bit, no flow control
TFTP server:   192.168.1.3/24
Board address: an unused address in 192.168.1.0/24
```

Download Tftpd64 from its upstream release page:

<https://github.com/PJO2/tftpd64/releases/#release-v4.74>

Before transferring an image:

1. Confirm the SoC, NAND geometry, partition names, and installed bootloader.
2. Select the image type required by that bootloader.
3. Verify the image checksum from the same build output.
4. Start the console before resetting or powering the board.
5. Do not interrupt power during NAND erase or write operations.

When the board still boots Linux, use the standard upgrade path after checking
the checksum:

```sh
sha256sum /tmp/<matching-sysupgrade.bin>
sysupgrade /tmp/<matching-sysupgrade.bin>
```

A normal sysupgrade updates the UBI firmware content. It should not rewrite
the boot chain or `Factory`. If the board rejects the image or reports a
different layout, stop and use the board-specific recovery instructions.

## Public scope

This SDK contains only the authorized Linux board adaptation and build
metadata. Boot-chain binaries, raw device data, private original images,
calibration dumps, and internal validation records remain outside the public
tree. Results from another board or a simulated build must not be presented as
GS-R3000N-H4 hardware acceptance.

## Upstream project information

The original OpenWrt project introduction and community links are preserved in
[`README.openwrt.md`](README.openwrt.md). This README is the project-specific
entry point for the GS-R3000N-H4 SDK.

## License

OpenWrt components retain their upstream licenses. Board-specific source files
use the SPDX identifiers shown in each file.
