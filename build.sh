#!/bin/sh
set -eu

CONFIG_FILE="GS-R3000N-H4.config"
UPSTREAM_BASELINE="7722054025462cbc4cc6225cfe49ea0ad409b302"
BUILD_FIRMWARE=1
BUILD_SDK=1

usage() {
	cat <<EOF
Usage: $(basename "$0") [--firmware-only|--sdk-only]

Build the GS-R3000N-H4 OpenWrt firmware and SDK with the native OpenWrt
build commands. The default command builds both outputs.

Options:
  --firmware-only  Build only the firmware images.
  --sdk-only       Build only the OpenWrt SDK.
  -h, --help       Show this help.

The configuration seed is ${CONFIG_FILE}. See the OpenWrt build-system
documentation for host prerequisites and troubleshooting.
EOF
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		--firmware-only)
			BUILD_FIRMWARE=1
			BUILD_SDK=0
			;;
		--sdk-only)
			BUILD_FIRMWARE=0
			BUILD_SDK=1
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "ERROR: unsupported argument: $1" >&2
			usage >&2
			exit 2
			;;
	esac
	shift
done

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT_DIR"

[ -f "$CONFIG_FILE" ] || {
	echo "ERROR: missing $CONFIG_FILE" >&2
	exit 1
}
[ -f feeds.conf.default ] || {
	echo "ERROR: missing feeds.conf.default" >&2
	exit 1
}

# Use the number of processing units reported by the host for both native
# build stages. OpenWrt and the host documentation own prerequisite errors.
JOBS=$(nproc)

STATE_DIR=$(mktemp -d)
CONFIG_SAVED=0
CONFIG_OLD_SAVED=0
FEEDS_CONF_SAVED=0

if [ -e .config ] || [ -L .config ]; then
	mv .config "$STATE_DIR/config"
	CONFIG_SAVED=1
fi
if [ -e .config.old ] || [ -L .config.old ]; then
	mv .config.old "$STATE_DIR/config.old"
	CONFIG_OLD_SAVED=1
fi
if [ -e feeds.conf ] || [ -L feeds.conf ]; then
	mv feeds.conf "$STATE_DIR/feeds.conf"
	FEEDS_CONF_SAVED=1
fi

cleanup() {
	status=$?
	trap - EXIT HUP INT TERM
	rm -f .config .config.old
	if [ "$CONFIG_SAVED" -eq 1 ]; then
		mv "$STATE_DIR/config" .config
	fi
	if [ "$CONFIG_OLD_SAVED" -eq 1 ]; then
		mv "$STATE_DIR/config.old" .config.old
	fi
	rm -f feeds.conf
	if [ "$FEEDS_CONF_SAVED" -eq 1 ]; then
		mv "$STATE_DIR/feeds.conf" feeds.conf
	fi
	rm -rf "$STATE_DIR"
	exit "$status"
}
trap cleanup EXIT HUP INT TERM

cp "$CONFIG_FILE" .config
cp feeds.conf.default feeds.conf

./scripts/feeds update -a
./scripts/feeds install -a
make defconfig

if [ "$BUILD_FIRMWARE" -eq 1 ]; then
	make -j"$JOBS"
fi

if [ "$BUILD_SDK" -eq 1 ]; then
	make -j"$JOBS" target/sdk/compile \
		BASE_FEED="src-git --root=package base https://github.com/openwrt/openwrt.git^${UPSTREAM_BASELINE}"
fi

echo "OpenWrt output: bin/targets/mediatek/filogic"
