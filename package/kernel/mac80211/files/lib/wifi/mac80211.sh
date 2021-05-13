#!/bin/sh
. /lib/netifd/mac80211.sh

append DRIVERS "mac80211"

lookup_phy() {
	[ -n "$phy" ] && {
		[ -d /sys/class/ieee80211/$phy ] && return
	}

	local devpath
	config_get devpath "$device" path
	[ -n "$devpath" ] && {
		phy="$(mac80211_path_to_phy "$devpath")"
		[ -n "$phy" ] && return
	}

	local macaddr="$(config_get "$device" macaddr | tr 'A-Z' 'a-z')"
	[ -n "$macaddr" ] && {
		for _phy in /sys/class/ieee80211/*; do
			[ -e "$_phy" ] || continue

			[ "$macaddr" = "$(cat ${_phy}/macaddress)" ] || continue
			phy="${_phy##*/}"
			return
		done
	}
	phy=
	return
}

find_mac80211_phy() {
	local device="$1"

	config_get phy "$device" phy
	lookup_phy
	[ -n "$phy" -a -d "/sys/class/ieee80211/$phy" ] || {
		echo "PHY for wifi device $1 not found"
		return 1
	}
	config_set "$device" phy "$phy"

	config_get macaddr "$device" macaddr
	[ -z "$macaddr" ] && {
		config_set "$device" macaddr "$(cat /sys/class/ieee80211/${phy}/macaddress)"
	}

	return 0
}

check_mac80211_device() {
	config_get phy "$1" phy
	[ -z "$phy" ] && {
		find_mac80211_phy "$1" >/dev/null || return 0
		config_get phy "$1" phy
	}
	[ "$phy" = "$dev" ] && found=1
}

detect_mac80211() {
	devidx=0
	config_load wireless
	while :; do
		config_get type "radio$devidx" type
		[ -n "$type" ] || break
		devidx=$(($devidx + 1))
	done

	for _dev in /sys/class/ieee80211/*; do
		[ -e "$_dev" ] || continue

		dev="${_dev##*/}"

		found=0
		config_foreach check_mac80211_device wifi-device
		[ "$found" -gt 0 ] && continue

		mode_band="g"
		band_name='2G'
		channel="11"
		htmode=""
		ht_capab=""

		iw phy "$dev" info | grep -q 'Capabilities:' && htmode=HT20

		iw phy "$dev" info | grep -q '\* 5... MHz \[' && {
			mode_band="a"
			band_name='5G'
			channel=$(iw phy "$dev" info | grep '\* 5... MHz \[' | grep '(disabled)' -v -m 1 | sed 's/[^[]*\[\|\].*//g')
			iw phy "$dev" info | grep -q 'VHT Capabilities' && htmode="VHT80"
		}

		iw phy "$dev" info | grep -q '\* 5.... MHz \[' && {
			mode_band="ad"
			band_name='60G'
			channel=$(iw phy "$dev" info | grep '\* 5.... MHz \[' | grep '(disabled)' -v -m 1 | sed 's/[^[]*\[\|\|\].*//g')
			iw phy "$dev" info | grep -q 'Capabilities:' && htmode="HT20"
		}

		[ -n "$htmode" ] && ht_capab="set wireless.radio${devidx}.htmode=$htmode"

		path="$(mac80211_phy_to_path "$dev")"
		if [ -n "$path" ]; then
			dev_id="set wireless.radio${devidx}.path='$path'"
		else
			dev_id="set wireless.radio${devidx}.macaddr=$(cat /sys/class/ieee80211/${dev}/macaddress)"
		fi

		mac_last_4="$(awk -F ":" '{printf toupper($5$6)}' /sys/class/ieee80211/${dev}/macaddress)"
		#driver="$(grep ^DRIVER= /sys/class/ieee80211/${dev}/device/uevent | awk -F '=' '{print $2}')"
		board_name="$(awk -F ',' '{print $2}' /tmp/sysinfo/board_name)"
		ssid="${board_name}_${band_name}_${mac_last_4}"
		ssid=$(echo $ssid | tr 'a-z' 'A-Z')

		uci -q batch <<-EOF
			set wireless.radio${devidx}=wifi-device
			set wireless.radio${devidx}.type=mac80211
			set wireless.radio${devidx}.channel=${channel}
			set wireless.radio${devidx}.hwmode=11${mode_band}
			${dev_id}
			${ht_capab}
			set wireless.radio${devidx}.disabled=0

			set wireless.default_radio${devidx}=wifi-iface
			set wireless.default_radio${devidx}.device=radio${devidx}
			set wireless.default_radio${devidx}.network=lan
			set wireless.default_radio${devidx}.mode=ap
			set wireless.default_radio${devidx}.ssid=${ssid}
			set wireless.default_radio${devidx}.encryption=none
EOF
		uci -q commit wireless

		devidx=$(($devidx + 1))
	done
}
