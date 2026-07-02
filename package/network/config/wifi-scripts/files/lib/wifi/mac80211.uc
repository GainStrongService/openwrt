#!/usr/bin/env ucode
import { readfile } from "fs";
import * as uci from 'uci';

const bands_order = [ "6G", "5G", "2G" ];
const htmode_order = [ "EHT", "HE", "VHT", "HT" ];

let board = json(readfile("/etc/board.json"));
if (!board.wlan)
	exit(0);

let idx = 0;
let commit;
let system_board_name = readfile("/tmp/sysinfo/board_name");
system_board_name = system_board_name ? trim(system_board_name) : "";
let is_oolite_mt7981b = match(system_board_name, /^gainstrong,oolite-mt7981b-v1-/);

let config = uci.cursor().get_all("wireless") ?? {};

function radio_exists(path, macaddr, phy, radio) {
	for (let name, s in config) {
		if (s[".type"] != "wifi-device")
			continue;
		if (radio != null && int(s.radio) != radio)
			continue;
		if (s.macaddr && lc(s.macaddr) == lc(macaddr))
			return true;
		if (s.phy == phy)
			return true;
		if (!s.path || !path)
			continue;
		if (substr(s.path, -length(path)) == path)
			return true;
	}
}

function oolite_default_ssid(band_name) {
	let phy0_macaddr = readfile("/sys/class/ieee80211/phy0/macaddress");
	let mac_suffix = "";

	if (phy0_macaddr) {
		let mac_clean = join("", split(trim(phy0_macaddr), ":"));
		if (length(mac_clean) >= 4)
			mac_suffix = uc(substr(mac_clean, -4));
	}

	return "MT7981_" + mac_suffix + "_" + uc(band_name);
}

for (let phy_name, phy in board.wlan) {
	let info = phy.info;
	if (!info || !length(info.bands))
		continue;

	let radios = length(info.radios) > 0 ? info.radios : [{ bands: info.bands }];
	for (let radio in radios) {
		while (config[`radio${idx}`])
			idx++;
		let name = "radio" + idx;

		let s = "wireless." + name;
		let si = "wireless.default_" + name;

		let band_name = filter(bands_order, (b) => radio.bands[b])[0];
		if (!band_name)
			continue;

		let band = info.bands[band_name];
		let rband = radio.bands[band_name];
		let channel = rband.default_channel ?? "auto";

		let width = band.max_width;
		if (band_name == "2G")
			width = 20;
		else if (width > 80)
			width = 80;

		let htmode = filter(htmode_order, (m) => band[lc(m)])[0];
		if (htmode)
			htmode += width;
		else
			htmode = "NOHT";

		if (!phy.path)
			continue;

		let macaddr = trim(readfile(`/sys/class/ieee80211/${phy_name}/macaddress`));
		if (radio_exists(phy.path, macaddr, phy_name, radio.index))
			continue;

		let id = `phy='${phy_name}'`;
		if (match(phy_name, /^phy[0-9]/))
			id = `path='${phy.path}'`;

		band_name = lc(band_name);

		let country, encryption, defaults, num_global_macaddr, default_ssid, default_disabled;
		if (band_name == '6g') {
			country = '00';
			encryption = 'owe';
		} else {
			encryption = 'none';
		}
		if (board.wlan.defaults) {
			defaults = board.wlan.defaults.ssids?.[band_name]?.ssid ? board.wlan.defaults.ssids?.[band_name] : board.wlan.defaults.ssids?.all;
			country = board.wlan.defaults.country;
			if (!country && band_name != '2g')
				defaults = null;
			num_global_macaddr = board.wlan.defaults.ssids?.[band_name]?.mac_count;
		}
		if (is_oolite_mt7981b) {
			default_ssid = oolite_default_ssid(band_name);
			default_disabled = 0;
		} else {
			default_ssid = defaults?.ssid || "OpenWrt";
			default_disabled = defaults ? 0 : 1;
		}

		if (length(info.radios) > 0)
			id += `\nset ${s}.radio='${radio.index}'`;

		print(`set ${s}=wifi-device
set ${s}.type='mac80211'
set ${s}.${id}
set ${s}.band='${band_name}'
set ${s}.channel='${channel}'
set ${s}.htmode='${htmode}'
set ${s}.country='${country || ''}'
set ${s}.num_global_macaddr='${num_global_macaddr || ''}'

set ${si}=wifi-iface
set ${si}.device='${name}'
set ${si}.network='lan'
set ${si}.mode='ap'
set ${si}.ssid='${default_ssid}'
set ${si}.encryption='${defaults?.encryption || encryption}'
set ${si}.key='${defaults?.key || ""}'
set ${si}.disabled='${default_disabled}'

`);
		config[name] = {};
		commit = true;
	}
}

if (commit)
	print("commit wireless\n");
