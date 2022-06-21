
include $(TOPDIR)/rules.mk

PKG_NAME:=helium-gateway
PKG_VERSION:=v1.0.0-alpha.27
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-caldigit.ipk
PKG_SOURCE_URL:=https://github.com/helium/gateway-rs/releases/download/$(PKG_VERSION)/
PKG_HASH:=3bbb0941316f89461d6d3d5db75ea77332bd304ad891995a8de0977ec86eb013
PKG_CAT:=zcat
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/build

PKG_MAINTAINER:=Joe Guo <joe@gainstrong.cn>

include $(INCLUDE_DIR)/package.mk

define Build/Configure
	tar -C $(PKG_BUILD_DIR) -zxvf $(PKG_BUILD_DIR)/../data.tar.gz
endef

define Build/Compile
	true
endef

define Package/helium-gateway
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Helium
  TITLE:=The Helium Gateway to attach your LoRa gateway to the Helium Blockchain
  DEPENDS:=+curl
endef

define Package/helium-gateway/install
	$(CP) $(PKG_BUILD_DIR)/etc $(1)/
	$(CP) $(PKG_BUILD_DIR)/usr $(1)/
	$(SED) 's/caldigit/gainstrong/' $(1)/etc/helium_gateway/*.toml
endef

$(eval $(call BuildPackage,helium-gateway))
