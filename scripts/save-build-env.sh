#!/bin/bash

export BUILD_CONF_DIR=files/build
rm -rf $BUILD_CONF_DIR
mkdir -p $BUILD_CONF_DIR
git log -40 --stat > $BUILD_CONF_DIR/git-log.txt
cp -a .config $BUILD_CONF_DIR/build-config-full.txt
cat /etc/os-release > $BUILD_CONF_DIR/build-host-os.txt
