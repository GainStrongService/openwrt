#!/bin/bash

BUILD_CONF_DIR=files/build
rm -rf $BUILD_CONF_DIR
mkdir -p $BUILD_CONF_DIR
git log -40 --stat > $BUILD_CONF_DIR/git-log.txt
cp -a .config $BUILD_CONF_DIR
cat /etc/os-release > $BUILD_CONF_DIR/build-host-os.txt
dpkg -l | grep ^i | awk '{print $2"\t"$3}' > $BUILD_CONF_DIR/build-host-pkg.txt
