#!/bin/bash

PROCUCT_NAME="Oolite-V1.0"

cp $PROCUCT_NAME.config .config

OPENWRT_VERSION=$(grep ^VERSION_NUMBER include/version.mk | tail -n 1 | awk -F , '{print $3}' | sed 's/.$//')
COMMIT_VERSION=$(./scripts/getver.sh)
echo "CONFIG_KERNEL_BUILD_USER=\"$OPENWRT_VERSION-$COMMIT_VERSION\"" >> .config

make package/symlinks
if [ $? -ne 0 ]; then
    echo "Error: Package feeds update failed, please try again."
    exit 1
fi

# 判断feeds/luci/collections/luci-light/Makefile中是否包含luci-proto-ipv6依赖
if grep -q "luci-proto-ipv6" feeds/luci/collections/luci-light/Makefile; then
  # 如果包含,则使用sed命令删除该行
  sed -i "/luci-proto-ipv6/d" feeds/luci/collections/luci-light/Makefile
  echo "已删除luci Makefile中的luci-proto-ipv6依赖"
else
  echo "luci Makefile中未发现luci-proto-ipv6依赖,无需处理"  
fi

make defconfig
make package/busybox/clean
make -j8 V=sc
