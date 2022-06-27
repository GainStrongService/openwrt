#
# Copyright (C) 2018 GainStrong Inc.
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=lora-sx1276
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/lora-sx1276
  SUBMENU:=Other modules
  TITLE:=Semtech SX1276 driver support for MiniBox-LoRa
endef

define Package/lora-sx1276/description
  Kernel module for Semtech SX1276 driver support for MiniBox-LoRa
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
	$(CP) ./libs/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) CC="$(TARGET_CC)"
endef

define Package/lora-sx1276/install
	$(INSTALL_DIR) $(1)/etc/modules.d
	$(INSTALL_DIR) $(1)/lib/modules/$(LINUX_VERSION)
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_DIR) $(1)/lib/semtech

	$(CP) ./drivers/99-lora-sx1276 $(1)/etc/modules.d/99-lora-sx1276
	$(CP) ./drivers/lora-sx1276.ko_4.14.206 $(1)/lib/modules/$(LINUX_VERSION)/lora-sx1276.ko
	$(CP) ./libs/libsx1276.so $(1)/lib/semtech
	$(CP) ./libs/libsx1276.a $(1)/lib/semtech
	$(CP) ./libs/sx1276.h $(1)/lib/semtech
	$(CP) $(PKG_BUILD_DIR)/lora-test $(1)/sbin/lora-test
endef

$(eval $(call BuildPackage,lora-sx1276))
