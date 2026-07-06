#!/usr/bin/env bash
set -Eeuo pipefail

PRODUCT_NAME="Minibox-V2"
PRODUCT_DIST="GainStrong Minibox V2.0"
CONFIG_FILE="Minibox-V2.0.config"
usage() {
	cat <<EOF
Usage: $(basename "$0") [options]

Build a GainStrong Minibox V2.0 firmware image for the ramips/mt76x8 target.

Options:
  --log <file>     Write all build output to <file> (default: logs/build-minibox-v2-*.log)
  --skip-feeds     Skip './scripts/feeds update -a' and './scripts/feeds install -a'
  -h, --help       Show this help
EOF
}

log_file=""
skip_feeds=0

while [ $# -gt 0 ]; do
	case "$1" in
	--log)
		log_file="${2:-}"
		if [ -z "$log_file" ]; then
			echo "Missing value for --log" >&2
			exit 2
		fi
		shift 2
		;;
	--skip-feeds)
		skip_feeds=1
		shift
		;;
	-h|--help)
		usage
		exit 0
		;;
	*)
		echo "Unknown argument: $1" >&2
		usage >&2
		exit 2
		;;
	esac
done

build_version_code() {
	./scripts/getver.sh
}

build() {
	local openwrt_version version_code

	if [ ! -f "$CONFIG_FILE" ]; then
		echo "Missing $CONFIG_FILE" >&2
		exit 1
	fi

	cp "$CONFIG_FILE" .config

	openwrt_version="$(./scripts/getver.sh)"
	version_code="$(build_version_code)"

	cat <<EOF >> .config

CONFIG_KERNEL_BUILD_DOMAIN="$openwrt_version"
CONFIG_KERNEL_BUILD_USER="$PRODUCT_NAME"
CONFIG_VERSION_DIST="$PRODUCT_DIST"
CONFIG_VERSION_CODE="$version_code"
EOF

	if [ "$skip_feeds" -eq 0 ]; then
		./scripts/feeds update -a
		./scripts/feeds install -a
	fi

	make defconfig
	make package/base-files/clean
	make -j"$(nproc)" V=sc
}

mkdir -p logs
if [ -z "$log_file" ]; then
	log_file="logs/build-minibox-v2-$(date +%Y%m%d-%H%M%S).log"
fi

echo "Build log: $log_file"
exec 3>&1
exec >"$log_file" 2>&1

on_err() {
	local rc=$?
	echo "Build failed (rc=$rc). See $log_file" >&3
	tail -n 80 "$log_file" >&3 || true
	exit "$rc"
}

trap on_err ERR

build

echo "Build done. See $log_file" >&3
