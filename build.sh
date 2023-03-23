#!/bin/bash

cp OoliteBox-V1.0.config .config
VERSION=$(./scripts/getver.sh)
echo "CONFIG_KERNEL_BUILD_DOMAIN=\"$VERSION\"" >> .config
make package/symlinks
make defconfig
make package/busybox/clean
make -j8 V=sc
