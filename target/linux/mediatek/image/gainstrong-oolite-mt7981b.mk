define Device/gainstrong_oolite-mt7981b-v1-nand-common
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin
  IMAGE/factory.bin := append-ubi
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

define define_device_config
  define Device/gainstrong_oolite-mt7981b-v1-$(2)-$(1)-boot
    DEVICE_VENDOR := GainStrong
    DEVICE_MODEL := Oolite-MT7981B V1 $(if $(findstring dev-board,$(2)),Dev Board,SoM) ($(1) boot)
    DEVICE_DTS := mt7981b-gainstrong-oolite-mt7981b-v1-$(2)-$(1)-boot
    SUPPORTED_DEVICES += gainstrong,oolite-mt7981b-v1-$(1)-boot
    DEVICE_DTS_DIR := ../dts
    DEVICE_PACKAGES := kmod-mt7981-firmware mt7981-wo-firmware kmod-usb3 kmod-mmc
    ifeq ($(1),nand)
      $(call Device/gainstrong_oolite-mt7981b-v1-nand-common)
    else ifneq ($(1),nor)
      IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
    endif
  endef
  TARGET_DEVICES += gainstrong_oolite-mt7981b-v1-$(2)-$(1)-boot
endef

# NAND config
$(eval $(call define_device_config,nand,som))
$(eval $(call define_device_config,nand,dev-board))

# eMMC config
$(eval $(call define_device_config,emmc,som))
$(eval $(call define_device_config,emmc,dev-board))

# SD card config
$(eval $(call define_device_config,sdcard,som))
$(eval $(call define_device_config,sdcard,dev-board))

# NOR config
$(eval $(call define_device_config,nor,som))
$(eval $(call define_device_config,nor,dev-board))
