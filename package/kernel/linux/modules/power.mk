#
# Copyright (C) 2006-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

POWER_MENU:=Power Supply Support

define KernelPackage/bq27xxx
  SUBMENU:=$(POWER_MENU)
  TITLE:=BQ27XXX support
  DEPENDS:=+kmod-i2c-core
  KCONFIG:= \
          CONFIG_POWER_SUPPLY=y \
          CONFIG_BATTERY_BQ27XXX=y \
          CONFIG_BATTERY_BQ27XXX_DT_UPDATES_NVM=y \
          CONFIG_BATTERY_BQ27XXX_I2C=y
  FILES:=$(LINUX_DIR)/drivers/power/supply/bq27xxx_battery_i2c.ko
endef

define KernelPackage/bq27xxx/description
 BQ27XXX support
endef

$(eval $(call KernelPackage,bq27xxx))



define KernelPackage/bq2429x
  SUBMENU:=$(POWER_MENU)
  TITLE:=BQ2429X charger IC support
  DEPENDS:=+kmod-i2c-core
  KCONFIG:=CONFIG_CHARGER_BQ2429X
  FILES:=$(LINUX_DIR)/drivers/power/supply/bq2429x_charger.ko
endef

define KernelPackage/bq2429x/description
 BQ2429X charger IC support
endef

$(eval $(call KernelPackage,bq2429x))

