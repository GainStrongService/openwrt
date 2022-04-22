#!/bin/bash

source scripts/save-build-env.sh

cp Oolite5-MiniBox3.config .config
VERSION=Gainstrong-$(./scripts/getver.sh)
echo "CONFIG_KERNEL_BUILD_DOMAIN=\"$VERSION\"" >> .config
make package/symlinks
make defconfig
make package/busybox/clean
make -j9 V=sc
