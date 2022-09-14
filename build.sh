#!/bin/bash

source scripts/save-build-env.sh

cp PrinterServer.config .config
VERSION=Gainstrong-$(./scripts/getver.sh)
echo "CONFIG_KERNEL_BUILD_DOMAIN=\"$VERSION\"" >> .config
make package/symlinks

rm ./package/feeds/packages/node &> /dev/null
rm ./package/feeds/packages/node-* &> /dev/null
./scripts/feeds install -a -p node
make defconfig

make package/busybox/clean
make -j8 V=sc
