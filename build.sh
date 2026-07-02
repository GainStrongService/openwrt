#!/usr/bin/env bash

set -euo pipefail

PRODUCT_NAME="Oolite-MT7981B-V1"
CONFIG_FILE="MT7981.config"
TARGET_NAME="filogic"
DEVICE_PREFIX="CONFIG_TARGET_DEVICE_mediatek_${TARGET_NAME}_DEVICE_gainstrong_oolite-mt7981b-v1"
FLASH_TYPES=("nand" "emmc" "sdcard" "nor" "all")
HALOW_SOURCE="taixin-fmac-linux-driver-v2.2.1-41305.zip"
HALOW_SOURCE_SHA256="66941241c8562f276320ec0816e767b84c5b9c917fca394e8f2dddce2116ac1d"
JOBS="${JOBS:-$(nproc)}"
LOG_DIR="${LOG_DIR:-logs}"
BUILD_STAMP="$(date +%Y%m%d-%H%M%S)"
flash_type=""

usage() {
	printf 'Usage: %s <nand|emmc|sdcard|nor|all>\n' "$0" >&2
}

is_valid_flash_type() {
	local input="$1"
	local flash_type

	for flash_type in "${FLASH_TYPES[@]}"; do
		[ "$input" = "$flash_type" ] && return 0
	done

	return 1
}

choose_flash_type() {
	local choice

	if [ "$#" -eq 1 ]; then
		is_valid_flash_type "$1" || {
			usage
			exit 1
		}
		flash_type="$1"
		return
	fi

	if [ "$#" -ne 0 ] || [ ! -t 0 ]; then
		usage
		exit 1
	fi

	printf 'Please choose a flash type:\n'
	PS3="Enter the corresponding number and press Enter: "
	select choice in "${FLASH_TYPES[@]}"; do
		if [ -n "$choice" ]; then
			flash_type="$choice"
			return
		fi
		printf 'Invalid selection, please try again.\n'
	done
}

append_halow_packages() {
	local source_path="dl/${HALOW_SOURCE}"
	local source_hash

	if [ ! -f "$source_path" ]; then
		cat >> .config <<EOF

# CONFIG_PACKAGE_kmod-taixin-fmac is not set
# CONFIG_PACKAGE_taixin-fmac-tools is not set
EOF
		printf 'Taixin Wi-Fi HaLow driver source not found: %s\n' "$source_path"
		printf 'Wi-Fi HaLow support will not be included. Contact GainStrong technical support for the commercial source package.\n'
		return
	fi

	source_hash="$(sha256sum "$source_path" | awk '{print $1}')"
	if [ "$source_hash" != "$HALOW_SOURCE_SHA256" ]; then
		printf 'Error: unexpected Taixin Wi-Fi HaLow driver source hash for %s\n' "$source_path" >&2
		printf 'Expected: %s\n' "$HALOW_SOURCE_SHA256" >&2
		printf 'Actual:   %s\n' "$source_hash" >&2
		exit 1
	fi

	cat >> .config <<EOF

CONFIG_PACKAGE_kmod-taixin-fmac=y
CONFIG_PACKAGE_taixin-fmac-tools=y
EOF
	printf 'Taixin Wi-Fi HaLow driver source found; enabling HaLow packages.\n'
}

append_device_profiles() {
	local flash_type="$1"
	local flash_type_option

	if [ "$flash_type" = "all" ]; then
		for flash_type_option in nand emmc sdcard nor; do
			printf '%s-dev-board-%s-boot=y\n' "$DEVICE_PREFIX" "$flash_type_option" >> .config
			printf '%s-som-%s-boot=y\n' "$DEVICE_PREFIX" "$flash_type_option" >> .config
		done
	else
		printf '%s-dev-board-%s-boot=y\n' "$DEVICE_PREFIX" "$flash_type" >> .config
		printf '%s-som-%s-boot=y\n' "$DEVICE_PREFIX" "$flash_type" >> .config
	fi
}

run_logged() {
	local name="$1"
	shift

	local log_file="${LOG_DIR}/${BUILD_STAMP}-${name}.log"
	printf 'Running %s, log: %s\n' "$name" "$log_file"
	if ! "$@" >"$log_file" 2>&1; then
		printf 'Error: %s failed. Last log lines:\n' "$name" >&2
		tail -n 80 "$log_file" >&2 || true
		exit 1
	fi
}

choose_flash_type "$@"

[ -f "$CONFIG_FILE" ] || {
	printf 'Error: missing %s\n' "$CONFIG_FILE" >&2
	exit 1
}

mkdir -p "$LOG_DIR"
cp "$CONFIG_FILE" .config

revision="$(./scripts/getver.sh)"
cat >> .config <<EOF

CONFIG_KERNEL_BUILD_DOMAIN="$revision"
CONFIG_VERSION_DIST="$PRODUCT_NAME"
EOF

append_halow_packages
append_device_profiles "$flash_type"

run_logged "feeds-update" ./scripts/feeds update -a
run_logged "feeds-install" ./scripts/feeds install -a
run_logged "defconfig-${flash_type}" make defconfig
run_logged "build-${flash_type}" make -j"$JOBS" V=sc

printf 'Build completed for %s. Logs are in %s.\n' "$flash_type" "$LOG_DIR"
