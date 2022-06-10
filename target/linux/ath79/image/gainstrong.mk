define Device/gainstrong-common
	$(Device/tplink)
	ATH_SOC := qca9531
	DEVICE_PACKAGES := kmod-usb2
endef

define Device/gainstrong-8mlzma
	$(Device/gainstrong-common)
	TPLINK_FLASHLAYOUT := 8Mlzma
	IMAGE_SIZE := 7936k
endef

define Device/gainstrong-16mlzma
	$(Device/gainstrong-common)
	TPLINK_FLASHLAYOUT := 16Mlzma
	IMAGE_SIZE := 15872k
endef

define Device/gainstrong-32mlzma
	$(Device/gainstrong-common)
	TPLINK_FLASHLAYOUT := 32Mlzma
	IMAGE_SIZE := 32256k
endef

define Device/gainstrong-64mlzma
	$(Device/gainstrong-common)
	TPLINK_FLASHLAYOUT := 64Mlzma
	IMAGE_SIZE := 65024k
endef


###### Oolite v5 ################################
define Device/gainstrong_oolite-v5-8m
	$(Device/gainstrong-8mlzma)
	DEVICE_TITLE := GainStrong Oolite V5.X (8M flash)
	SUPPORTED_DEVICES += oolite-v5-8m
endef
TARGET_DEVICES += gainstrong_oolite-v5-8m

define Device/gainstrong_oolite-v5-16m
	$(Device/gainstrong-16mlzma)
	DEVICE_TITLE := GainStrong Oolite V5.X (16M flash)
	SUPPORTED_DEVICES += oolite-v5-16m
endef
TARGET_DEVICES += gainstrong_oolite-v5-16m

define Device/gainstrong_oolite-v5-32m
	$(Device/gainstrong-32mlzma)
	DEVICE_TITLE := GainStrong Oolite V5.X (32M flash)
	SUPPORTED_DEVICES += oolite-v5-32m
endef
TARGET_DEVICES += gainstrong_oolite-v5-32m

define Device/gainstrong_oolite-v5-64m
	$(Device/gainstrong-64mlzma)
	DEVICE_TITLE := GainStrong Oolite V5.X (64M flash)
	SUPPORTED_DEVICES += oolite-v5-64m
endef
TARGET_DEVICES += gainstrong_oolite-v5-64m


###### Minibox v3 ################################
define Device/gainstrong_minibox-v3-8m
	$(Device/gainstrong-8mlzma)
	DEVICE_TITLE := GainStrong Minibox V3.X (8M flash)
	SUPPORTED_DEVICES += minibox-v3-8m
endef
TARGET_DEVICES += gainstrong_minibox-v3-8m

define Device/gainstrong_minibox-v3-16m
	$(Device/gainstrong-16mlzma)
	DEVICE_TITLE := GainStrong Minibox V3.X (16M flash)
	SUPPORTED_DEVICES += minibox-v3-16m
endef
TARGET_DEVICES += gainstrong_minibox-v3-16m

define Device/gainstrong_minibox-v3-32m
	$(Device/gainstrong-32mlzma)
	DEVICE_TITLE := GainStrong Minibox V3.X (32M flash)
	SUPPORTED_DEVICES += minibox-v3-32m
endef
TARGET_DEVICES += gainstrong_minibox-v3-32m

define Device/gainstrong_minibox-v3-64m
	$(Device/gainstrong-64mlzma)
	DEVICE_TITLE := GainStrong Minibox V3.X (64M flash)
	SUPPORTED_DEVICES += minibox-v3-64m
endef
TARGET_DEVICES += gainstrong_minibox-v3-64m
