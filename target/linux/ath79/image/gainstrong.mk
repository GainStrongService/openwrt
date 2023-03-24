define oolitebox-v1/common
	$(Device/tplink-v1)
	SOC := qca9531
	DEVICE_VENDOR := GainStrong
	DEVICE_MODEL := OoliteBox V1.0
	DEVICE_PACKAGES := kmod-usb2
endef

define Device/gainstrong_oolitebox-v1-16m
	$(oolitebox-v1/common)
	TPLINK_FLASHLAYOUT := 16Mlzma
	DEVICE_VARIANT := 16M
	SUPPORTED_DEVICES += oolitebox-v1-16m
endef
TARGET_DEVICES += gainstrong_oolitebox-v1-16m

define Device/gainstrong_oolitebox-v1-32m
	$(oolitebox-v1/common)
	TPLINK_FLASHLAYOUT := 32Mlzma
	DEVICE_VARIANT := 32M
	SUPPORTED_DEVICES += oolitebox-v1-32m
endef
TARGET_DEVICES += gainstrong_oolitebox-v1-32m

define Device/gainstrong_oolitebox-v1-64m
	$(oolitebox-v1/common)
	TPLINK_FLASHLAYOUT := 64Mlzma
	DEVICE_VARIANT := 64M
	SUPPORTED_DEVICES += oolitebox-v1-64m
endef
TARGET_DEVICES += gainstrong_oolitebox-v1-64m
