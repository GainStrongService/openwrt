define Device/gainstrong_oolite-v5-64m
  SOC := qca9531
  IMAGE_SIZE := 65216k
  DEVICE_VENDOR := Gainstrong
  DEVICE_MODEL := Oolite v5
  DEVICE_VARIANT := 64M
  DEVICE_PACKAGES := kmod-usb2
endef
TARGET_DEVICES += gainstrong_oolite-v5-64m

define Device/gainstrong_oolite-v5-32m
  SOC := qca9531
  IMAGE_SIZE := 32448k
  DEVICE_VENDOR := Gainstrong
  DEVICE_MODEL := Oolite v5
  DEVICE_VARIANT := 32M
  DEVICE_PACKAGES := kmod-usb2
endef
TARGET_DEVICES += gainstrong_oolite-v5-32m

define Device/gainstrong_oolite-v5-16m
  SOC := qca9531
  IMAGE_SIZE := 16064k
  DEVICE_VENDOR := Gainstrong
  DEVICE_MODEL := Oolite v5
  DEVICE_VARIANT := 16M
  DEVICE_PACKAGES := kmod-usb2
endef
TARGET_DEVICES += gainstrong_oolite-v5-16m