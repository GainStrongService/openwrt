#!/bin/bash

source scripts/save-build-env.sh

cp PrinterServer.config .config
VERSION=Gainstrong-$(./scripts/getver.sh)
echo "CONFIG_KERNEL_BUILD_DOMAIN=\"$VERSION\"" >> .config
make package/symlinks

# 删除OpenWrt自带的Node，解决不兼容QCA9531的问题
rm ./package/feeds/packages/node &> /dev/null
rm ./package/feeds/packages/node-* &> /dev/null
./scripts/feeds install -a -p node

make defconfig

make package/busybox/clean
make -j8 V=sc
