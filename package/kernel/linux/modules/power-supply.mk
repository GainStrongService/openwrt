#
# Copyright (C) 2026 GainStrong
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

POWER_SUPPLY_MENU:=Power supply modules

define KernelPackage/battery-bq27xxx
  SUBMENU:=$(POWER_SUPPLY_MENU)
  TITLE:=TI BQ27xxx battery fuel gauge support
  DEPENDS:=+kmod-i2c-core
  KCONFIG:= \
	CONFIG_POWER_SUPPLY=y \
	CONFIG_BATTERY_BQ27XXX \
	CONFIG_BATTERY_BQ27XXX_I2C \
	CONFIG_BATTERY_BQ27XXX_HDQ=n \
	CONFIG_BATTERY_BQ27XXX_DT_UPDATES_NVM=n
  FILES:= \
	$(LINUX_DIR)/drivers/power/supply/bq27xxx_battery.ko \
	$(LINUX_DIR)/drivers/power/supply/bq27xxx_battery_i2c.ko
  AUTOLOAD:=$(call AutoProbe,bq27xxx_battery bq27xxx_battery_i2c)
endef

define KernelPackage/battery-bq27xxx/description
 Kernel modules for TI BQ27xxx I2C battery fuel gauges.
endef

$(eval $(call KernelPackage,battery-bq27xxx))
