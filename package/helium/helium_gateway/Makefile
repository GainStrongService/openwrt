
include $(TOPDIR)/rules.mk

PKG_NAME:=helium_gateway
PKG_VERSION:=1.0.0
PKG_RELEASE:=1.alpha.23

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/helium/gateway-rs.git
PKG_SOURCE_VERSION:=54c6a32f4a021b6abdedd1c769363b8d73feb158

PKG_MAINTAINER:=Joe Guo <joe@gainstrong.cn>

include $(INCLUDE_DIR)/package.mk

define Build/Compile
	true
endef

define Build/Configure
	true
endef

define Package/helium_gateway
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Helium
  TITLE:=The Helium Gateway to attach your LoRa gateway to the Helium Blockchain
  DEPENDS:=+curl
endef

define Package/helium_gateway/install
	$(CP) $(PKG_BUILD_DIR)/package/caldigit/data/* $(1)/
	$(SED) 's/caldigit/gainstrong/' $(1)/etc/helium_gateway/settings.toml
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/helium_gateway $(1)/usr/bin/
endef

$(eval $(call BuildPackage,helium_gateway))
