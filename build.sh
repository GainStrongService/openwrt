#!/bin/bash

# Constants
PRODUCT_NAME="Oolite-MT7981B-V1"

if [ -z "$(grep 21.02 include/version.mk)" ]; then
  TARGET_NAME="filogic"
else
  TARGET_NAME="mt7981"
fi

DEVICE_PREFIX="CONFIG_TARGET_DEVICE_mediatek_${TARGET_NAME}_DEVICE_gainstrong_oolite-mt7981b-v1"
FLASH_TYPES=("nand" "emmc" "sdcard" "nor" "all")

# Function to validate the user input
validate_input() {
  local input=$1
  for flash_type in "${FLASH_TYPES[@]}"; do
    if [ "$input" == "$flash_type" ]; then
      return 0
    fi
  done
  return 1
}

# Check if the argument is valid
if [[ $# -eq 1 ]]; then
  if validate_input "$1"; then
    user_input=$1
  else
    echo "Error: The input must be a valid flash type (nand, emmc, sdcard, nor, all)"
    exit 1
  fi
else
  # Prompt user to choose flash_type
  echo "Please choose a flash type:"
  PS3="Enter the corresponding number (1-5) and press Enter: "
  select choice in "${FLASH_TYPES[@]}"; do
    if [ -n "$choice" ]; then
      user_input=$choice
      break
    else
      echo "Invalid selection, please try again."
    fi
  done
fi

# Function to build for each flash type
build_for_flash_type() {
  local flash_type=$1

  cp MT7981.config .config

  VERSION=$(./scripts/getver.sh)

  cat << EOF >> .config
# Add an empty line

CONFIG_KERNEL_BUILD_DOMAIN="$VERSION"
CONFIG_KERNEL_BUILD_USER="$PRODUCT_NAME"
CONFIG_VERSION_DIST="$PRODUCT_NAME"
EOF

  if [ "$flash_type" == "all" ]; then
    for flash_type_option in nand emmc sdcard nor; do
      echo "$DEVICE_PREFIX-dev-board-${flash_type_option}-boot=y" >> .config
      echo "$DEVICE_PREFIX-som-${flash_type_option}-boot=y" >> .config
    done
  else
    echo "$DEVICE_PREFIX-dev-board-${flash_type}-boot=y" >> .config
    echo "$DEVICE_PREFIX-som-${flash_type}-boot=y" >> .config
  fi

  # Execute the build commands
  make package/symlinks
  make defconfig
  make -j8 V=sc
}

build_for_flash_type "$user_input"
