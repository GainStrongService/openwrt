#
# Copyright (C) 2021 Xue Liu <liuxuenetmail@gmail>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=sx1302-hal
PKG_VERSION:=2.1.0
PKG_RELEASE:=1


PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/Lora-net/sx1302_hal.git
PKG_SOURCE_VERSION:=4b42025d1751e04632c0b04160e0d29dbbb222a5
PKG_HASH:=ec8854b8399799b7e950bae9d394e4372759a553b90a3d1b94b802a8f095650b
INST_ROOT:=/root/$(PKG_NAME)

PKG_MAINTAINER:=Joe Guo <joe@gainstrong.cn>

include $(INCLUDE_DIR)/package.mk

TARGET_CFLAGS += -O2 -Wall -Wextra -std=c99 -Iinc -I. -I../libtools/inc

define Package/sx1302-hal
  SECTION:=net
  CATEGORY:=Network
  TITLE:=SX1302/SX1303 HAL
  DEPENDS:=+kmod-spi-dev
endef

define Package/sx1302-hal/install
	$(INSTALL_DIR) $(1)$(INST_ROOT)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/packet_forwarder/lora_pkt_fwd $(1)$(INST_ROOT)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tools/reset_lgw.sh $(1)$(INST_ROOT)
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/packet_forwarder/global_conf.json* $(1)$(INST_ROOT)
	$(INSTALL_DATA) ./files/local_conf.json* $(1)$(INST_ROOT)
	ln -s global_conf.json.sx1250.CN490 $(1)$(INST_ROOT)/global_conf.json
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/util_*/{net_downlink,chip_id,boot,spectral_scan} $(1)$(INST_ROOT)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libloragw/test* $(1)$(INST_ROOT)
endef


$(eval $(call BuildPackage,sx1302-hal))
