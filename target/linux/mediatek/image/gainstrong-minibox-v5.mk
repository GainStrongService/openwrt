define Device/gainstrong_minibox-v5
  DEVICE_VENDOR := GainStrong
  DEVICE_MODEL := Minibox V5
  DEVICE_DTS := mt7981b-gainstrong-minibox-v5
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTS_OVERLAY := \
	mt7981b-gainstrong-minibox-v5-emmc \
	mt7981b-gainstrong-minibox-v5-sd \
	mt7981b-gainstrong-minibox-v5-nand \
	mt7981b-gainstrong-minibox-v5-nor
  DEVICE_DTC_FLAGS := --pad 4096
  DEVICE_DTS_LOADADDR := 0x43f00000
  DEVICE_PACKAGES := kmod-eeprom-at24 kmod-gpio-pca953x \
		kmod-leds-gpio kmod-mmc kmod-mt7915e kmod-mt7981-firmware \
		kmod-usb3 mt7981-wo-firmware -uboot-envtools
  KERNEL_LOADADDR := 0x44000000
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  IMAGES := sysupgrade.itb
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-with-rootfs | \
	pad-rootfs | append-metadata
endef
TARGET_DEVICES += gainstrong_minibox-v5
