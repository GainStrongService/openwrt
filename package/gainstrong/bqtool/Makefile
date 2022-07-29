include $(TOPDIR)/rules.mk

PKG_NAME:=bqtool
PKG_VERSION:=2017.03.16
PKG_RELEASE:=1


PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://git.ti.com/git/bms-linux/bqtool.git
PKG_SOURCE_VERSION:=44f7e5222e907c2078ae617552888fd54e262925

PKG_MAINTAINER:=Joe Guo <joe@gainstrong.cn>

include $(INCLUDE_DIR)/package.mk

define Package/bqtool
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Utility for TI's bq27xxx family of gas gauges
  URL:=https://git.ti.com/cgit/bms-linux/bqtool/
  DEPENDS:=+kmod-i2c-core
endef

define Package/bqtool/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bqtool $(1)/bin/
endef


$(eval $(call BuildPackage,bqtool))
