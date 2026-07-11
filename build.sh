#!/usr/bin/env bash
set -Eeuo pipefail

PRODUCT_NAME="Minibox-V5"
PRODUCT_DIST="GainStrong Minibox V5.0"
CONFIG_FILE="Minibox-V5.0.config"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--log <file>] [--skip-feeds] [--jobs <count>]

Build the OpenWrt firmware-only Minibox V5 profile. This branch does not add,
package, or emit ATF, U-Boot, full-flash, Bluetooth, or cellular-modem
components.

Options:
  --log <file>     Write build output to this file.
  --skip-feeds     Reuse the currently installed feeds.
  --jobs <count>   Parallel build jobs (default: number of host CPUs).
  -h, --help       Show this help.
EOF
}

LOG_FILE=""
SKIP_FEEDS=0
JOBS="$(nproc)"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --log)
      [ "$#" -ge 2 ] || { echo "ERROR: --log requires a path" >&2; exit 2; }
      LOG_FILE="$2"
      shift 2
      ;;
    --skip-feeds)
      SKIP_FEEDS=1
      shift
      ;;
    --jobs)
      [ "$#" -ge 2 ] || { echo "ERROR: --jobs requires a count" >&2; exit 2; }
      JOBS="$2"
      shift 2
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
done

case "$JOBS" in
  ''|*[!0-9]*) echo "ERROR: invalid job count: $JOBS" >&2; exit 2 ;;
  0) echo "ERROR: job count must be greater than zero" >&2; exit 2 ;;
esac

ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "$ROOT_DIR"
[ -f "$CONFIG_FILE" ] || { echo "ERROR: missing $CONFIG_FILE" >&2; exit 1; }

REVISION="$(./scripts/getver.sh)"
REVISION_DATE="${REVISION%-*}"
REVISION_COMMIT="${REVISION##*-}"
case "$REVISION_COMMIT" in
  ???????) ;;
  *) echo "ERROR: invalid GainStrong revision: $REVISION" >&2; exit 1 ;;
esac
case "$REVISION_COMMIT" in
  *[!0-9a-f]*) echo "ERROR: invalid GainStrong revision: $REVISION" >&2; exit 1 ;;
esac
VERSION_CODE="${REVISION_DATE}-g${REVISION_COMMIT}"
if [ -n "$(git status --porcelain --untracked-files=all --ignore-submodules=dirty)" ]; then
  VERSION_CODE="${VERSION_CODE}-dirty"
fi

if [ -z "$LOG_FILE" ]; then
  LOG_FILE="logs/build-minibox-v5-${VERSION_CODE}.log"
fi
[ ! -e "$LOG_FILE" ] || { echo "ERROR: refusing to overwrite $LOG_FILE" >&2; exit 1; }
mkdir -p "$(dirname "$LOG_FILE")"

ARTIFACT_DIR="bin/targets/mediatek/filogic"
if [ -d "$ARTIFACT_DIR" ] &&
   find "$ARTIFACT_DIR" -maxdepth 1 -type f -name "*${VERSION_CODE}*" -print -quit |
     grep -q .; then
  echo "ERROR: refusing to overwrite existing ${VERSION_CODE} artifacts" >&2
  exit 1
fi

run_logged() {
  local stage="$1"
  shift

  printf '%s -> %s\n' "$stage" "$LOG_FILE"
  "$@" >>"$LOG_FILE" 2>&1
}

: >"$LOG_FILE"

if [ "$SKIP_FEEDS" -eq 0 ]; then
  [ ! -e feeds.conf ] || {
    echo "ERROR: local feeds.conf overrides the public feeds.conf.default" >&2
    echo "Remove the override or use --skip-feeds with already installed public feeds" >&2
    exit 1
  }
  run_logged "Updating feeds" ./scripts/feeds update -a
  run_logged "Installing feeds" ./scripts/feeds install -a
fi

cp "$CONFIG_FILE" .config
cat >>.config <<EOF
CONFIG_KERNEL_BUILD_DOMAIN="$VERSION_CODE"
CONFIG_KERNEL_BUILD_USER="$PRODUCT_NAME"
CONFIG_VERSION_DIST="$PRODUCT_DIST"
CONFIG_VERSION_CODE="$VERSION_CODE"
EOF

run_logged "Generating configuration" make defconfig
if grep -q '^CONFIG_FEED_3ginfo=y$' .config; then
  echo "ERROR: third-party 3ginfo feed is enabled in firmware repositories" >&2
  exit 1
fi
run_logged "Building firmware" make -j"$JOBS"

manifest="$(find "$ARTIFACT_DIR" -maxdepth 1 -type f \
  -name "*${VERSION_CODE}*filogic.manifest" -print -quit)"
sysupgrade="$(find "$ARTIFACT_DIR" -maxdepth 1 -type f \
  -name "*${VERSION_CODE}*gainstrong_minibox-v5*squashfs-sysupgrade.itb" \
  -print -quit)"
initramfs="$(find "$ARTIFACT_DIR" -maxdepth 1 -type f \
  -name "*${VERSION_CODE}*gainstrong_minibox-v5*initramfs-recovery.itb" \
  -print -quit)"

[ -n "$manifest" ] || { echo "ERROR: package manifest was not generated" >&2; exit 1; }
[ -n "$sysupgrade" ] || { echo "ERROR: sysupgrade FIT was not generated" >&2; exit 1; }
[ -n "$initramfs" ] || { echo "ERROR: initramfs FIT was not generated" >&2; exit 1; }

forbidden_packages='^(arm-trusted-firmware|trusted-firmware-a|bluez|bt-|kmod-bluetooth|uboot-|minibox-v5-modem|umbim|kmod-usb-net-cdc-mbim|kmod-usb-serial-option|luci-proto-mbim)'
if grep -Eq "$forbidden_packages" "$manifest"; then
  echo "ERROR: excluded package found in firmware manifest" >&2
  grep -E "$forbidden_packages" "$manifest" >&2
  exit 1
fi

grep -q '^kmod-mtd-rw ' "$manifest" || {
  echo "ERROR: kmod-mtd-rw is missing from the firmware manifest" >&2
  exit 1
}

if find "$ARTIFACT_DIR" -maxdepth 1 -type f \
    \( -name "*${VERSION_CODE}*bootloader*" -o \
       -name "*${VERSION_CODE}*fullimage*" -o \
       -name "*${VERSION_CODE}*preloader*" -o \
       -name "*${VERSION_CODE}*u-boot*" \) | grep -q .; then
  echo "ERROR: bootloader or full-flash artifact was generated" >&2
  exit 1
fi

printf 'Firmware: %s\n' "$sysupgrade"
printf 'Initramfs: %s\n' "$initramfs"
printf 'Manifest: %s\n' "$manifest"
sha256sum "$sysupgrade" "$initramfs"
