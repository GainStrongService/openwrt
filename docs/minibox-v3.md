# GainStrong MiniBox V3.X

OpenWrt support for the GainStrong MiniBox V3.0 and MiniBox V3.2.  Both are
QCA9531 boards with one WAN and one LAN port.  The V3.2 carries a QCA9887
5 GHz card on the SoC PCIe bus, the V3.0 leaves that position unpopulated.

One image supports both products and every flash size the board is built
with: the 5 GHz radio is discovered at runtime, and the partition table is
resolved from the real chip size at boot.

## Hardware

| Item | MiniBox V3.0 | MiniBox V3.2 |
| --- | --- | --- |
| SoC | QCA9531, MIPS 24Kc | QCA9531, MIPS 24Kc |
| 2.4 GHz | QCA9531 2x2 802.11n | QCA9531 2x2 802.11n |
| 5 GHz | not populated | QCA9887 1x1 802.11ac, PCIe `168c:0050` |
| RAM | 64 or 128 MiB DDR2 | 128 MiB DDR2 |
| Flash | SPI-NOR, 16 / 32 / 64 MiB | SPI-NOR, 16 / 32 / 64 MiB |
| Ethernet | 1x WAN + 1x LAN, 10/100 | 1x WAN + 1x LAN, 10/100 |
| USB | 1x USB 2.0 | 1x micro USB, USB 2.0 host |
| Status LED | one, GPIO14, active low | one, GPIO14, active low |
| Reset button | GPIO17, active low | GPIO17, active low |
| Console | UART header inside the housing | UART header inside the housing |

## Flash Layout

The calibration data sits at the very end of the flash, so a static partition
table would only fit the one chip size it was written for.  Instead the device
tree uses the `gainstrong-dynamic-mtd` parser, which adds two properties on
top of `fixed-partitions`:

- `tail-partition`: the offset in `reg` is measured from the end of the flash.
- `dynamic-end`: the size in `reg` is the distance from the end of the flash.

The parser lives in
`target/linux/generic/hack-6.12/490-add-gainstrong-dynamic-mtd-partition-support.patch`.

Resulting layout, one device tree for every size:

| Region | 16 MiB | 32 MiB | 64 MiB | Size |
| --- | --- | --- | --- | --- |
| `u-boot` | `0x000000` | `0x000000` | `0x000000` | `0x020000` |
| `firmware` | `0x020000` | `0x020000` | `0x020000` | flash - `0x040000` |
| `u-boot-env` | `0xfe0000` | `0x1fe0000` | `0x3fe0000` | `0x010000` |
| `art` | `0xff0000` | `0x1ff0000` | `0x3ff0000` | `0x010000` |

A 32 or 64 MiB unit simply ends up with a larger `firmware` partition and
overlay; nothing in the build assumes a particular size.

The full feature set produces a sysupgrade image of roughly 11 MiB, so check
the result against the smallest flash in the batch being programmed: the
`firmware` partition is `0xfc0000` on a 16 MiB unit, `0x1fc0000` on 32 MiB and
`0x3fc0000` on 64 MiB.

The `firmware` partition uses the `tplink,firmware` splitter, and the image is
built with the TP-Link v1 `16Mlzma` header layout to keep it compact while its
kernel and rootfs offsets stay self-consistent.

### Why there is no factory image

The TP-Link v1 factory format is padded out to the full layout, which would
write over the U-Boot environment that sits directly below the calibration
data.  Only `sysupgrade.bin` is provided.

## MAC Addresses and Calibration

| Consumer | Source |
| --- | --- |
| Label MAC (2.4 GHz radio) | ART `0x1002`, 6 bytes |
| `eth0` (LAN) | label MAC + 1 |
| `eth1` (WAN) | label MAC + 2 |
| 5 GHz radio | MAC and calibration from ART `0x5000` |

The label address is the 2.4 GHz radio address, so `label-mac-device` points
at `&wmac` rather than at an Ethernet port.

Both ports derive their address from the label MAC.  `mac-address-increment`
no longer exists in this tree, so the increment travels as an argument of a
`compatible = "mac-base"` cell instead:

```dts
nvmem-cells = <&macaddr_art_1002 1>;   /* label + 1 */
```

Port names do not follow node names: ag71xx takes `eth%d` from
`devm_alloc_etherdev()`, so the numbering follows probe order.  On this board
the GMAC at `1a000000` comes up as `eth0`, which makes `&eth1` the LAN port and
`&eth0` the WAN port, and that is why the increments look swapped in the DTS.

The 2.4 GHz radio takes its calibration data from ART `0x1000`, `0x440` bytes.

The QCA9887 on the V3.2 has no EEPROM of its own, so the module cannot hand
`ath10k` any calibration and the radio stays down with:

```text
ath10k_pci 0000:00:00.0: failed to read device EEPROM at 0000
ath10k_pci 0000:00:00.0: failed to read calibration data from EEPROM: -22
ath10k_pci 0000:00:00.0: could not probe fw (-22)
```

The per-card calibration block is kept in ART at `0x5000`, `0x844` bytes, and
is passed to the driver through a `wifi@0,0` child of the PCIe node:

```dts
&pcie0 {
	status = "okay";

	wifi@0,0 {
		compatible = "qcom,ath10k";
		reg = <0x0000 0 0 0 0>;
		nvmem-cells = <&cal_art_5000>;
		nvmem-cell-names = "calibration";
	};
};
```

Firmware and board data come from the mainline packages `ath10k-firmware-qca9887`
(`firmware-5.bin`) and `ath10k-board-qca9887` (`board.bin`), both pulled in by the
device definition in `target/linux/ath79/image/generic.mk`.  The `ath10k-ct`
variants are not used: that driver reaches the firmware through the diag window
instead of the CE pipes and never completes the handshake on this card.

## Default Network

`target/linux/ath79/generic/base-files/etc/board.d/02_network` maps:

```text
LAN: eth0   (jack next to the reset button)
WAN: eth1   (jack on the micro-USB power side)
```

Note that this is the opposite of what the ath79 default assumes, and also the
opposite of what the vendor's 12.09 firmware shipped with: on this board the
LAN jack is the one beside the reset button, while the jack on the micro-USB
power side is WAN.  If a board revision turns out to be wired the other way
round, swap the two names on that one line.

## Default Wireless

Both radios come up enabled on first boot.  The defaults are written into
`/etc/board.json` by `target/linux/ath79/generic/base-files/etc/board.d/00_wlan`
and consumed by `lib/wifi/mac80211.uc` when it generates `/etc/config/wireless`:

- SSID `MiniBox-V3.X-XXXX-2.4G` and `MiniBox-V3.X-XXXX-5G`, where `XXXX` are
  the last four digits of the label MAC in upper case, so units on the same
  shelf do not share an SSID.  The suffix sits in front of the band so that the
  two networks of one unit sort together in a scan list and match the case
  label.
- Country `US`.  A band is only enabled by default when a default SSID exists
  for it, and the 5 GHz band additionally needs a country.
- No encryption, which is what upstream generates when a default SSID is
  supplied.  Pass an encryption type and key to `ucidef_set_wireless` to
  change that.

## Shared Image and PCIe

The PCIe controller is enabled unconditionally.  On MiniBox V3.2 the QCA9887
is enumerated and `ath10k` brings up the 5 GHz radio, taking its calibration
from the `wifi@0,0` node described above.  On MiniBox V3.0 no endpoint is
present, the bus stays idle and only the on-SoC 2.4 GHz radio comes up.  No
separate image or configuration is needed for either product.

## Firmware Features

The build profile enables:

- LuCI with English and Simplified Chinese.
- WireGuard (`luci-proto-wireguard`, `rpcd-mod-wireguard`).
- OpenVPN (OpenSSL variant) with EasyRSA and the LuCI app.
- Policy based routing (`luci-app-pbr`).
- `kmod-mtd-rw` for explicit maintenance access to read-only MTD partitions.
- USB storage: `usbutils`, block mount, UAS, and the FAT, exFAT and NTFS3
  drivers, plus `dosfstools`, `exfat-fsck` and `exfat-mkfs` so that a stick can
  be checked or formatted from the box itself.

The overlay stays on jffs2, which is built into the kernel on this target, so
no ext4 module is shipped for it.

## Build

Run the build helper from the repository root:

```sh
./build-minibox-v3.sh
```

Options:

```sh
./build-minibox-v3.sh --skip-feeds
./build-minibox-v3.sh --log logs/my-minibox-v3-build.log
```

The script copies `Minibox-V3.config` to `.config`, appends the version code
from `scripts/getver.sh`, runs `make defconfig` and builds with all local
cores.  The version code is the commit timestamp plus the short hash, for
example `YYYYMMDD-HHMM-XXXXXXX`.

Images land in:

```text
bin/targets/ath79/generic/
```

Expected artifact:

```text
*-ath79-generic-gainstrong_minibox_v3-squashfs-sysupgrade.bin
```

## Verification

Before flashing:

- `make defconfig` accepts `CONFIG_TARGET_ath79_generic_DEVICE_gainstrong_minibox-v3=y`.
- The image filename carries the version code.
- The image fits the `firmware` partition of the batch being programmed.

After booting a 16 MiB unit:

```sh
cat /proc/mtd                              # firmware size must be 0xfc0000
cat /tmp/sysinfo/model                     # GainStrong MiniBox V3.X
cat /sys/class/ieee80211/phy0/macaddress   # label MAC
cat /sys/class/net/eth0/address            # label MAC + 1 (LAN)
cat /sys/class/net/eth1/address            # label MAC + 2 (WAN)
ls /sys/class/leds/                        # green:system only
logread | grep -i restart                  # reset button -> KEY_RESTART
lspci -nn                                  # V3.2: 168c:0050 bound to ath10k_pci
iw dev                                     # V3.2: a 2.4 GHz and a 5 GHz interface
```

On a 32 or 64 MiB unit, `cat /proc/mtd` shows `firmware` growing with the
flash and `art` staying the last 64 KiB.

Radio:

- V3.0: `iw dev` lists the 2.4 GHz phy only, `dmesg | grep -i pcie` is clean.
- V3.2: `iw dev` also lists a 5 GHz phy, and `dmesg | grep -i ath10k` shows
  firmware boot without a board-data error.
