#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'EOF'
Usage: scripts/mk-minibox-v25-aliases.sh [--dir <out_dir>] [--rev <revision>] [--dry-run]

Create user-friendly, versioned symlinks for GainStrong Minibox V2.5 artifacts.

Defaults:
  --dir  bin/targets/ramips/mt76x8
  --rev  $(./scripts/getver.sh)

Examples:
  scripts/mk-minibox-v25-aliases.sh
  scripts/mk-minibox-v25-aliases.sh --rev 20260603-1530-123abcd
EOF
}

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR_DEFAULT="${ROOT_DIR}/bin/targets/ramips/mt76x8"
DEVICE_SUFFIX="ramips-mt76x8-gainstrong_minibox-v25"

out_dir="$OUT_DIR_DEFAULT"
rev="$("${ROOT_DIR}/scripts/getver.sh")"
dry_run=0

while [[ $# -gt 0 ]]; do
	case "$1" in
	--dir)
		out_dir="${2:-}"
		if [[ -z "$out_dir" ]]; then
			echo "Missing value for --dir" >&2
			exit 2
		fi
		shift 2
		;;
	--rev)
		rev="${2:-}"
		if [[ -z "$rev" ]]; then
			echo "Missing value for --rev" >&2
			exit 2
		fi
		shift 2
		;;
	--dry-run)
		dry_run=1
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

if [[ ! -d "$out_dir" ]]; then
	echo "Output directory does not exist: $out_dir" >&2
	exit 1
fi

out_dir="$(cd -- "$out_dir" && pwd)"
rev_base="${rev%-dirty}"

shopt -s nullglob

find_one() {
	local pattern="$1"
	local pattern_fallback="${2:-}"
	local best=""
	local file
	local -a matches=( "$out_dir"/$pattern )

	if [[ ${#matches[@]} -eq 0 && -n "$pattern_fallback" ]]; then
		matches=( "$out_dir"/$pattern_fallback )
	fi

	if [[ ${#matches[@]} -eq 0 ]]; then
		return 1
	fi

	for file in "${matches[@]}"; do
		if [[ -z "$best" || "$file" -nt "$best" ]]; then
			best="$file"
		fi
	done

	printf "%s\n" "$best"
}

link_one() {
	local alias="$1"
	local target="$2"
	local alias_path="${out_dir}/${alias}"
	local target_base

	target_base="$(basename -- "$target")"

	if [[ $dry_run -eq 1 ]]; then
		printf "ln -sf %q %q\n" "$target_base" "$alias_path"
		return 0
	fi

	ln -sf -- "$target_base" "$alias_path"
	printf "alias: %s -> %s\n" "$alias" "$target_base"
}

echo "out_dir=$out_dir"
echo "rev=$rev"

sysupgrade_pattern="*-${rev}*-${DEVICE_SUFFIX}-squashfs-sysupgrade.bin"
sysupgrade_pattern_fallback="*-${rev_base}*-${DEVICE_SUFFIX}-squashfs-sysupgrade.bin"

if ! sysupgrade="$(find_one "$sysupgrade_pattern" "$sysupgrade_pattern_fallback")"; then
	echo "missing: sysupgrade image (pattern: ${sysupgrade_pattern}|${sysupgrade_pattern_fallback})" >&2
	exit 1
fi

link_one "minibox-v25-sysupgrade-${rev}.bin" "$sysupgrade"
