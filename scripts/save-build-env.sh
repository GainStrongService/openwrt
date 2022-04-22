#!/bin/bash

rm -rf files/build
mkdir -p files/build
git log -40 --stat > files/build/git-log.txt
cat /etc/os-release > files/build/build-host-os.txt
dpkg -l | grep ^i | awk '{print $2"\t"$3}' > files/build/build-host-pkg.txt
