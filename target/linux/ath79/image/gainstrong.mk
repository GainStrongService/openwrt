define Device/gainstrong_minibox-v3
	$(Device/tplink-v1)
	SOC := qca9531
	DEVICE_VENDOR := GainStrong
	DEVICE_MODEL := MiniBox V3.0
	DEVICE_PACKAGES := kmod-usb2
	TPLINK_FLASHLAYOUT := 64Mlzma
	SUPPORTED_DEVICES += minibox-v3
endef
TARGET_DEVICES += gainstrong_minibox-v3
