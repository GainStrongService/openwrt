include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=taixin-fmac
PKG_VERSION:=2.2.1.41305
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=2.2.1-41305
PKG_SOURCE:=taixin-fmac-linux-driver-v$(PKG_SOURCE_VERSION).zip
PKG_SOURCE_HASH:=66941241c8562f276320ec0816e767b84c5b9c917fca394e8f2dddce2116ac1d
PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/taixin-fmac-linux-driver-v$(PKG_SOURCE_VERSION)
PKG_UNPACK:= \
	[ -f "$(DL_DIR)/$(PKG_SOURCE)" ] || { \
		echo "Missing commercial Taixin FMAC driver source: $(DL_DIR)/$(PKG_SOURCE)" >&2; \
		echo "Contact GainStrong technical support to obtain this source package." >&2; \
		exit 1; \
	}; \
	echo "$(PKG_SOURCE_HASH)  $(DL_DIR)/$(PKG_SOURCE)" | sha256sum -c -; \
	unzip -d "$(PKG_BUILD_DIR)/.." -q "$(DL_DIR)/$(PKG_SOURCE)"
PKG_BUILD_PARALLEL:=1

PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define KernelPackage/taixin-fmac
  SUBMENU:=Wireless Drivers
  TITLE:=Taixin 802.11ah USB FMAC driver
  DEPENDS:=+kmod-usb-core
  FILES:=$(PKG_BUILD_DIR)/hgic_fmac/hgicf.ko
  AUTOLOAD:=$(call AutoProbe,hgicf)
endef

define Package/taixin-fmac-tools
  CATEGORY:=Utilities
  TITLE:=Taixin 802.11ah FMAC tools
  DEPENDS:=+kmod-taixin-fmac
endef

define Build/Prepare
	$(PKG_UNPACK)
	-find $(PKG_BUILD_DIR) -mindepth 1 -type f -not -name '.*' -not -name 'version.date' -printf '%T@\n' 2>/dev/null |\
		cut -d. -f1 | sort -n | tail -n1 > $(PKG_BUILD_DIR)/version.date
	find $(PKG_BUILD_DIR) -type f \( -name '*.c' -o -name '*.h' -o -name 'Makefile' -o -name 'Kconfig' -o -name '*.conf' -o -name '*.txt' -o -name '*.sh' \) \
		-exec sed -i 's/\r//g' {} +
	$(Build/Patch)
endef

define Build/Compile
	+$(KERNEL_MAKE) $(PKG_JOBS) \
		M="$(PKG_BUILD_DIR)/hgic_fmac" \
		KCFLAGS="-Wno-error" \
		CONFIG_HGICF=m \
		CONFIG_HGIC_USB=y \
		CONFIG_HGIC_AH=y \
		CONFIG_HGIC_DMA_ALIGN=y \
		CONFIG_COMPILE_ERR_SUPPRESS=y \
		modules
		$(MAKE) CC="$(TARGET_CC)" \
			CFLAGS="$(TARGET_CFLAGS) -D__linux__ -include arpa/inet.h -Wno-error=incompatible-pointer-types" \
		LDFLAGS="$(TARGET_LDFLAGS) -lm" \
		-C $(PKG_BUILD_DIR)/tools/test_app \
		hgpriv libnetat hgota hgicf
endef

define KernelPackage/taixin-fmac/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DIR) $(1)/lib/firmware
	$(INSTALL_CONF) ./files/hgicf.conf $(1)/etc/hgicf.conf
	$(INSTALL_DATA) $(CURDIR)/taixin-fmac-firmware_v1.6.3.5-23271_2023.5.23-usb.bin $(1)/lib/firmware/hgicf.bin
endef

define Package/taixin-fmac-tools/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tools/test_app/hgpriv $(1)/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tools/test_app/libnetat $(1)/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tools/test_app/hgota $(1)/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tools/test_app/hgicf $(1)/bin/
	$(INSTALL_BIN) ./files/ah-mode-switch $(1)/bin/
endef

$(eval $(call KernelPackage,taixin-fmac))
$(eval $(call BuildPackage,taixin-fmac-tools))
