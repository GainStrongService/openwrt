define Device/gainstrong-16mlzma
	$(Device/tplink-v1)
	SOC := qca9531
	DEVICE_VENDOR := Gainstrong
	TPLINK_FLASHLAYOUT := 16Mlzma
	DEVICE_VARIANT := 16M
	DEVICE_PACKAGES := kmod-usb2
endef

define Device/gainstrong-32mlzma
	$(Device/tplink-v1)
	SOC := qca9531
	DEVICE_VENDOR := Gainstrong
	TPLINK_FLASHLAYOUT := 32Mlzma
	DEVICE_VARIANT := 32M
	DEVICE_PACKAGES := kmod-usb2
endef

define Device/gainstrong-64mlzma
	$(Device/tplink-v1)
	SOC := qca9531
	DEVICE_VENDOR := Gainstrong
	TPLINK_FLASHLAYOUT := 64Mlzma
	DEVICE_VARIANT := 64M
	DEVICE_PACKAGES := kmod-usb2
endef


###### Oolite v5 ################################
define Device/gainstrong_oolite-v5-16m
	$(Device/gainstrong-16mlzma)
	DEVICE_MODEL := Oolite v5
	SUPPORTED_DEVICES += oolite-v5-16m
endef
TARGET_DEVICES += gainstrong_oolite-v5-16m

define Device/gainstrong_oolite-v5-32m
	$(Device/gainstrong-32mlzma)
	DEVICE_MODEL := Oolite v5
	SUPPORTED_DEVICES += oolite-v5-32m
endef
TARGET_DEVICES += gainstrong_oolite-v5-32m

define Device/gainstrong_oolite-v5-64m
	$(Device/gainstrong-64mlzma)
	DEVICE_MODEL := Oolite v5
	SUPPORTED_DEVICES += oolite-v5-64m
endef
TARGET_DEVICES += gainstrong_oolite-v5-64m


###### Minibox v3 ################################
define Device/gainstrong_minibox-v3-16m
	$(Device/gainstrong-16mlzma)
	DEVICE_MODEL := Minibox v3
	SUPPORTED_DEVICES += minibox-v3-16m
endef
TARGET_DEVICES += gainstrong_minibox-v3-16m

define Device/gainstrong_minibox-v3-32m
	$(Device/gainstrong-32mlzma)
	DEVICE_MODEL := Minibox v3
	SUPPORTED_DEVICES += minibox-v3-32m
endef
TARGET_DEVICES += gainstrong_minibox-v3-32m

define Device/gainstrong_minibox-v3-64m
	$(Device/gainstrong-64mlzma)
	DEVICE_MODEL := Minibox v3
	SUPPORTED_DEVICES += minibox-v3-64m
endef
TARGET_DEVICES += gainstrong_minibox-v3-64m
