#!/bin/bash

cp Oolite-V3.X.config .config
VERSION=$(./scripts/getver.sh)
echo "CONFIG_KERNEL_BUILD_USER=\"$VERSION\"" >> .config

make package/symlinks
if [ $? -ne 0 ]; then
    echo "Error: Package feeds update failed, please try again."
    exit 1
fi

make defconfig
make package/busybox/clean
make -j8 V=sc
