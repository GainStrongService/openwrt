define Device/gainstrong_oolite-mt7981b-v1-common
  DEVICE_VENDOR := GainStrong
  DEVICE_MODEL := Oolite-MT7981B V1 $(if $(findstring dev-board,$(1)),Dev Board,SoM)
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTC_FLAGS := --pad 4096
  DEVICE_DTS_LOADADDR := 0x43f00000
  DEVICE_PACKAGES := kmod-mmc kmod-usb3 \
	kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware \
	uboot-envtools
endef

define Device/gainstrong_oolite-mt7981b-v1-nand-sysupgrade
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  KERNEL_LOADADDR := 0x48000000
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

define Device/gainstrong_oolite-mt7981b-v1-fit-sysupgrade
  KERNEL_LOADADDR := 0x44000000
  KERNEL := kernel-bin | gzip
  IMAGES := sysupgrade.itb
  IMAGE_SIZE := $$(shell expr 64 + $$(CONFIG_TARGET_ROOTFS_PARTSIZE))m
  # The 25.12 Oolite flow only emits system upgrade FIT images in this tree.
  IMAGE/sysupgrade.itb := append-kernel | fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-with-rootfs | pad-rootfs | append-metadata
endef

define define_oolite_device
  define Device/gainstrong_oolite-mt7981b-v1-$(2)-$(1)-boot
    DEVICE_DTS := mt7981b-gainstrong-oolite-mt7981b-v1-$(2)-$(1)-boot
    $$(call Device/gainstrong_oolite-mt7981b-v1-common,$(2))
    ifeq ($(1),nand)
      $$(call Device/gainstrong_oolite-mt7981b-v1-nand-sysupgrade)
    else
      $$(call Device/gainstrong_oolite-mt7981b-v1-fit-sysupgrade)
    endif
    DEVICE_MODEL += ($(1) boot)
    ifeq ($(2),dev-board)
      DEVICE_PACKAGES += kmod-gpio-pca953x kmod-rtc-pcf8563
    endif
    SUPPORTED_DEVICES += gainstrong,oolite-mt7981b-v1-$(2)-$(1)-boot
  endef
  TARGET_DEVICES += gainstrong_oolite-mt7981b-v1-$(2)-$(1)-boot
endef

$(eval $(call define_oolite_device,nand,som))
$(eval $(call define_oolite_device,nand,dev-board))
$(eval $(call define_oolite_device,nor,som))
$(eval $(call define_oolite_device,nor,dev-board))
$(eval $(call define_oolite_device,sdcard,som))
$(eval $(call define_oolite_device,sdcard,dev-board))
$(eval $(call define_oolite_device,emmc,som))
$(eval $(call define_oolite_device,emmc,dev-board))
