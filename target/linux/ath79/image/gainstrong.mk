define Device/gainstrong_minibox-lte
	$(Device/tplink-v1)
	SOC := qca9531
	DEVICE_VENDOR := GainStrong
	DEVICE_MODEL := MiniBox LTE
	DEVICE_PACKAGES := kmod-usb2
	TPLINK_FLASHLAYOUT := 64Mlzma
	SUPPORTED_DEVICES += minibox-lte
endef
TARGET_DEVICES += gainstrong_minibox-lte
