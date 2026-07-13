#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

device="root@192.168.1.1"
client_iface=""
radio_iface="phy0-ap0"
ping_target="192.168.1.1"
iterations=1
interval=5
ping_count=120
ping_interval=0.1
max_scan_seconds=2.0
max_loss_percent=5.0
max_rtt_ms=2000
log_root="${ROOT_DIR}/logs"

usage() {
	cat <<'EOF'
Usage: scripts/test-minibox-v25-wifi-scan.sh --client-iface <iface> [options]

Measure AP scan disruption while SSH uses a wired control path and ping uses
an already connected WiFi client interface.

Options:
  --device <user@host>        SSH destination (default: root@192.168.1.1)
  --client-iface <iface>      Local WiFi interface connected to the AP
  --radio-iface <iface>       Remote AP interface to scan (default: phy0-ap0)
  --ping-target <address>     Address reached through WiFi (default: 192.168.1.1)
  --iterations <count>        Number of scan rounds (default: 1)
  --interval <seconds>        Delay between rounds (default: 5)
  --ping-count <count>        Ping packets per round (default: 120)
  --ping-interval <seconds>   Ping interval (default: 0.1)
  --max-scan-seconds <value>  Maximum scan duration (default: 2.0)
  --max-loss-percent <value>  Maximum packet loss (default: 5.0)
  --max-rtt-ms <value>        Maximum ping RTT (default: 2000)
  --log-root <directory>      Test log directory (default: logs)
  -h, --help                  Show this help

The script does not configure WiFi or routes. Connect the local client interface
to the target AP first, and make sure SSH reaches the device over Ethernet.
EOF
}

die() {
	echo "error: $*" >&2
	exit 2
}

require_value() {
	local option="$1"
	local value="${2:-}"

	[[ -n "$value" ]] || die "missing value for ${option}"
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--device)
		require_value "$1" "${2:-}"
		device="$2"
		shift 2
		;;
	--client-iface)
		require_value "$1" "${2:-}"
		client_iface="$2"
		shift 2
		;;
	--radio-iface)
		require_value "$1" "${2:-}"
		radio_iface="$2"
		shift 2
		;;
	--ping-target)
		require_value "$1" "${2:-}"
		ping_target="$2"
		shift 2
		;;
	--iterations)
		require_value "$1" "${2:-}"
		iterations="$2"
		shift 2
		;;
	--interval)
		require_value "$1" "${2:-}"
		interval="$2"
		shift 2
		;;
	--ping-count)
		require_value "$1" "${2:-}"
		ping_count="$2"
		shift 2
		;;
	--ping-interval)
		require_value "$1" "${2:-}"
		ping_interval="$2"
		shift 2
		;;
	--max-scan-seconds)
		require_value "$1" "${2:-}"
		max_scan_seconds="$2"
		shift 2
		;;
	--max-loss-percent)
		require_value "$1" "${2:-}"
		max_loss_percent="$2"
		shift 2
		;;
	--max-rtt-ms)
		require_value "$1" "${2:-}"
		max_rtt_ms="$2"
		shift 2
		;;
	--log-root)
		require_value "$1" "${2:-}"
		log_root="$2"
		shift 2
		;;
	-h|--help)
		usage
		exit 0
		;;
	*)
		die "unknown option: $1"
		;;
	esac
done

[[ -n "$client_iface" ]] || die "--client-iface is required"
[[ "$client_iface" =~ ^[[:alnum:]_.:-]+$ ]] || die "invalid client interface"
[[ "$radio_iface" =~ ^[[:alnum:]_.:-]+$ ]] || die "invalid radio interface"
[[ "$iterations" =~ ^[1-9][0-9]*$ ]] || die "iterations must be a positive integer"
[[ "$ping_count" =~ ^[1-9][0-9]*$ ]] || die "ping count must be a positive integer"

for command in awk date iw ping ssh tee; do
	command -v "$command" >/dev/null || die "required command not found: $command"
done

float_gt() {
	awk -v lhs="$1" -v rhs="$2" 'BEGIN { exit !(lhs > rhs) }'
}

parse_loss() {
	awk -F, '/packet loss/ {
		value = $3
		gsub(/[^0-9.]/, "", value)
		print value
	}' "$1"
}

parse_max_rtt() {
	awk -F= '/^(rtt|round-trip) / {
		split($2, values, "/")
		gsub(/^[[:space:]]+/, "", values[3])
		print values[3]
	}' "$1"
}

parse_scan_value() {
	local key="$1"
	local file="$2"

	sed -n "s/.*${key}=\\([^[:space:]]*\\).*/\\1/p" "$file" | tail -n 1
}

remote_counters() {
	ssh "${ssh_options[@]}" "$device" sh -s -- "$radio_iface" <<'EOF'
radio_iface="$1"
disconnects="$(logread | grep -c "${radio_iface}: AP-STA-DISCONNECTED")"
errors="$(dmesg | grep -Eic 'mt76.*(watchdog|timeout|reset|stuck)')"
printf '%s %s\n' "$disconnects" "$errors"
EOF
}

run_remote_scan() {
	ssh "${ssh_options[@]}" "$device" sh -s -- "$radio_iface" <<'EOF'
radio_iface="$1"
start="$(awk '{ print $1 }' /proc/uptime)"
output="$(iw dev "$radio_iface" scan 2>&1)"
rc=$?
end="$(awk '{ print $1 }' /proc/uptime)"
duration="$(awk -v start="$start" -v end="$end" 'BEGIN { printf "%.2f", end - start }')"
bss_count="$(printf '%s\n' "$output" | grep -c '^BSS ')"
first_line="$(printf '%s\n' "$output" | sed -n '1p')"
printf 'rc=%s duration=%s bss=%s first=%s\n' "$rc" "$duration" "$bss_count" "$first_line"
EOF
}

timestamp="$(date +%Y%m%d-%H%M%S)"
run_dir="${log_root%/}/minibox-v25-wifi-scan-${timestamp}"
mkdir -p "$run_dir"
summary_log="${run_dir}/summary.log"
exec 3>&1 4>&2
exec >"$summary_log" 2>&1

print_summary() {
	local status=$?

	trap - EXIT
	exec 1>&3 2>&4
	cat "$summary_log"
	exit "$status"
}

trap print_summary EXIT

ssh_options=(
	-o BatchMode=yes
	-o ConnectTimeout=5
	-o ServerAliveInterval=5
	-o ServerAliveCountMax=3
)

echo "device=$device"
echo "client_iface=$client_iface"
echo "radio_iface=$radio_iface"
echo "ping_target=$ping_target"
echo "iterations=$iterations"
echo "run_dir=$run_dir"

ssh "${ssh_options[@]}" "$device" "iw dev '$radio_iface' info" >/dev/null

link_state="$(iw dev "$client_iface" link)"
printf '%s\n' "$link_state"
grep -q '^Connected to ' <<<"$link_state" || die "client interface is not connected"

baseline_file="${run_dir}/baseline-ping.log"
LC_ALL=C ping -q -I "$client_iface" -i "$ping_interval" -W 1 -c 20 \
	"$ping_target" >"$baseline_file" 2>&1 || true
baseline_loss="$(parse_loss "$baseline_file")"
[[ -n "$baseline_loss" ]] || die "could not parse baseline ping result"
if float_gt "$baseline_loss" 0; then
	cat "$baseline_file"
	die "baseline packet loss is ${baseline_loss}%"
fi

failures=0
for ((round = 1; round <= iterations; round++)); do
	ping_file="${run_dir}/ping-${round}.log"
	scan_file="${run_dir}/scan-${round}.log"

	read -r disconnects_before errors_before < <(remote_counters)

	LC_ALL=C ping -q -I "$client_iface" -i "$ping_interval" -W 1 \
		-c "$ping_count" "$ping_target" >"$ping_file" 2>&1 &
	ping_pid=$!
	sleep 2
	run_remote_scan | tee "$scan_file"
	if ! wait "$ping_pid"; then
		:
	fi

	read -r disconnects_after errors_after < <(remote_counters)
	loss="$(parse_loss "$ping_file")"
	max_rtt="$(parse_max_rtt "$ping_file")"
	scan_duration="$(parse_scan_value duration "$scan_file")"
	scan_rc="$(parse_scan_value rc "$scan_file")"
	bss_count="$(parse_scan_value bss "$scan_file")"
	link_state="$(iw dev "$client_iface" link)"

	[[ -n "$loss" ]] || loss=100
	[[ -n "$max_rtt" ]] || max_rtt=999999
	[[ -n "$scan_duration" ]] || scan_duration=999999
	[[ -n "$scan_rc" ]] || scan_rc=255
	[[ -n "$bss_count" ]] || bss_count=0

	round_failed=0
	if [[ "$scan_rc" -ne 0 || "$bss_count" -eq 0 ]]; then
		echo "round=$round failure=scan rc=$scan_rc bss=$bss_count"
		round_failed=1
	fi
	if float_gt "$scan_duration" "$max_scan_seconds"; then
		echo "round=$round failure=scan-duration actual=$scan_duration max=$max_scan_seconds"
		round_failed=1
	fi
	if float_gt "$loss" "$max_loss_percent"; then
		echo "round=$round failure=packet-loss actual=$loss max=$max_loss_percent"
		round_failed=1
	fi
	if float_gt "$max_rtt" "$max_rtt_ms"; then
		echo "round=$round failure=max-rtt actual=$max_rtt max=$max_rtt_ms"
		round_failed=1
	fi
	if [[ "$disconnects_after" -gt "$disconnects_before" ]]; then
		echo "round=$round failure=client-disconnected"
		round_failed=1
	fi
	if [[ "$errors_after" -gt "$errors_before" ]]; then
		echo "round=$round failure=mt76-kernel-error"
		round_failed=1
	fi
	if ! grep -q '^Connected to ' <<<"$link_state"; then
		echo "round=$round failure=client-not-connected"
		round_failed=1
	fi

	echo "round=$round duration=${scan_duration}s loss=${loss}% max_rtt=${max_rtt}ms disconnect_delta=$((disconnects_after - disconnects_before)) error_delta=$((errors_after - errors_before))"
	if [[ "$round_failed" -ne 0 ]]; then
		failures=$((failures + 1))
	fi

	if [[ "$round" -lt "$iterations" ]]; then
		sleep "$interval"
	fi
done

echo "failures=$failures"
if [[ "$failures" -ne 0 ]]; then
	exit 1
fi
