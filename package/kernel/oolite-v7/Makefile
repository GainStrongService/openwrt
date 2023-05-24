# All rights reserved.
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=oolite-v7
PKG_VERSION:=2.2.1-23239
PKG_SOURCE:=oolite-v7-802.11ah-linux-driver-v$(PKG_VERSION).zip

PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/huge-ic-fmac-linux-driver-v$(PKG_VERSION)

PKG_UNPACK=unzip -d $(PKG_BUILD_DIR)/.. -q $(PKG_SOURCE)
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/oolite-v7
  SUBMENU:=Wireless Drivers
  TITLE:=Oolite V7 802.11ah USB mode driver
  DEPENDS += +kmod-usb-core
  FILES:=$(PKG_BUILD_DIR)/hgic_fmac/hgicf.ko
  AUTOLOAD:=$(call AutoProbe,hgicf)
endef

define Package/oolite-v7-tools
  CATEGORY:=Utilities
  TITLE:=Oolite V7 802.11ah tools for driver 
endef

define Build/Compile
	+$(MAKE) $(PKG_JOBS) -C "$(LINUX_DIR)" \
		$(KERNEL_MAKE_FLAGS) \
		$(PKG_MAKE_FLAGS) \
		M="$(PKG_BUILD_DIR)/hgic_fmac" \
    CONFIG_HGICF=m CONFIG_HGIC_USB=y EXTRA_CFLAGS="$(CFLAGS) -DCONFIG_HGIC_USB" \
		modules
	sed -i 's/#include <error.h>//g' $(PKG_BUILD_DIR)/tools/test_app/*
	$(MAKE) CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
    -C $(PKG_BUILD_DIR)/tools/test_app \
    hgpriv libnetat hgota hgicf
endef

define KernelPackage/oolite-v7/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DIR) $(1)/lib/firmware
	tr -d '\015' < $(PKG_BUILD_DIR)/hgicf.conf > $(PKG_BUILD_DIR)/hgicf-unix.conf
	sed -i '/^ssid=/c\ssid=oolite-v7-default' $(PKG_BUILD_DIR)/hgicf-unix.conf
	sed -i '/^mode=/c\mode=ap' $(PKG_BUILD_DIR)/hgicf-unix.conf
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/hgicf-unix.conf $(1)/etc/hgicf.conf
	$(CP) oolite-v7-802.11ah-firmware_v1.6.3.5-23271_2023.5.23-usb.bin $(1)/lib/firmware/hgicf.bin
endef

define Package/oolite-v7-tools/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tools/test_app/{hgpriv,libnetat,hgota,hgicf} $(1)/bin/
	$(INSTALL_BIN) ah-mode-switch $(1)/bin/
endef

$(eval $(call KernelPackage,oolite-v7))
$(eval $(call BuildPackage,oolite-v7-tools))
