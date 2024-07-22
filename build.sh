#!/bin/bash

PROCUCT_NAME="Oolite-V3.3"

OPENWRT_VERSION=$(grep ^VERSION_NUMBER include/version.mk | tail -n 1 | awk -F , '{print $3}' | sed 's/.$//')
COMMIT_VERSION=$(./scripts/getver.sh)

cp $PROCUCT_NAME.config .config
echo "CONFIG_KERNEL_BUILD_USER=\"$PROCUCT_NAME\"" >> .config
echo "CONFIG_KERNEL_BUILD_DOMAIN=\"$OPENWRT_VERSION-$COMMIT_VERSION\"" >> .config

make package/symlinks
if [ $? -ne 0 ]; then
    echo "Error: Package feeds update failed, please try again."
    exit 1
fi

make defconfig
make package/busybox/clean
make -j8 V=sc
