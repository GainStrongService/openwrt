#!/bin/bash

PROCUCT_NAME="GainStrong-Oolite-V3.4"

OPENWRT_VERSION=$(grep ^VERSION_NUMBER include/version.mk | tail -n 1 | awk -F , '{print $3}' | sed 's/.$//')
COMMIT_VERSION=$(./scripts/getver.sh)

cp $PROCUCT_NAME.config .config
echo "CONFIG_KERNEL_BUILD_USER=\"$PROCUCT_NAME\"" >> .config
echo "CONFIG_KERNEL_BUILD_DOMAIN=\"$OPENWRT_VERSION-$COMMIT_VERSION\"" >> .config

make package/symlinks
make defconfig
make package/busybox/clean
make -j8 V=sc
