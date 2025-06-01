include \$(TOPDIR)/rules.mk

PKG_NAME:=sps-agent
PKG_RELEASE:=1

include \$(INCLUDE_DIR)/package.mk

define Package/sps-agent
  SECTION:=utils
  CATEGORY:=Utilities
  DEPENDS:=+libubus-lua +libmosquitto-nossl +lua
  TITLE:=SPS Agent
endef

define Package/sps-agent/install
    \$(INSTALL_DIR) \$(1)/usr/bin
    \$(INSTALL_BIN) ./files/sps-agent.lua \$(1)/usr/bin/
    \$(INSTALL_DIR) \$(1)/etc/config
    \$(INSTALL_CONF) ./files/sps-agent.config \$(1)/etc/config/sps-agent
endef

\$(eval \$(call BuildPackage,sps-agent))

