#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/Oolite-v8-32MB
	NAME:=oolite-v8-32mb Device
	PACKAGES:=\
		kmod-usb-core kmod-usb3 kmod-sdhci-mt7620 \
		kmod-ledtrig-usbdev kmod-ata-core kmod-ata-ahci \
		kmod-usb3-mt7621
endef

define Profile/Oolite-v8-32MB/Description
	Package set for Oolite-v8-32MB device
endef
$(eval $(call Profile,Oolite-v8-32MB))
