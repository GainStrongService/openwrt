#!/bin/bash

cp -a Luci-Makefile feeds/luci/collections/luci/Makefile
cp Oolite-34S-LoRa.config .config
VERSION=Gainstrong-$(./scripts/getver.sh)
echo "CONFIG_KERNEL_BUILD_DOMAIN=\"$VERSION\"" >> .config
make defconfig
make -j9 V=sc
