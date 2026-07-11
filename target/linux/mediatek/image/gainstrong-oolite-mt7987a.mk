define Device/gainstrong_oolite-mt7987a
  DEVICE_VENDOR := GainStrong
  DEVICE_MODEL := Oolite-MT7987A
  DEVICE_DTS := mt7987a-gainstrong-oolite-mt7987a
  DEVICE_DTS_OVERLAY := \
	mt7987a-gainstrong-oolite-mt7987a-nor \
	mt7987a-gainstrong-oolite-mt7987a-nand \
	mt7987a-gainstrong-oolite-mt7987a-emmc \
	mt7987a-gainstrong-oolite-mt7987a-sd
  DEVICE_DTS_CONFIG := config-mt7987a-gainstrong-oolite-mt7987a
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTC_FLAGS := --pad 4096
  DEVICE_DTS_LOADADDR := 0x4ff00000
  DEVICE_PACKAGES := mt7987-2p5g-phy-firmware \
	kmod-mt7990-firmware kmod-mt7992-firmware kmod-mt7992-23-firmware \
	kmod-usb3 -uboot-envtools
  KERNEL_LOADADDR := 0x40000000
  KERNEL := kernel-bin | lzma
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  IMAGES := sysupgrade.itb
  IMAGE_SIZE := 15360k
  IMAGE/sysupgrade.itb := append-kernel | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-with-rootfs | \
	pad-rootfs | append-metadata | check-size
endef
TARGET_DEVICES += gainstrong_oolite-mt7987a
