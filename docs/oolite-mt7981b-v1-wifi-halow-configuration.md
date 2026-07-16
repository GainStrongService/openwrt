# Oolite-MT7981B-V1 Wi-Fi HaLow Configuration Guide

This guide applies to the Oolite-MT7981B-V1 evaluation board firmware supplied with the Taixin USB Wi-Fi HaLow module.

## Overview

Wi-Fi HaLow is managed by the Taixin `hgicf` driver and the `hgpriv` command. It is separate from the MT7981B 2.4 GHz and 5 GHz Wi-Fi interfaces, so its SSID, frequency, and channel are not configured on the standard OpenWrt LuCI wireless page.

Connect to the board by SSH and run the commands below as `root`.

```sh
ssh root@192.168.1.1
```

The HaLow network interface is `hg0`.

## Check the current settings

```sh
hgpriv hg0 get mode
hgpriv hg0 get ssid
hgpriv hg0 get bss_bw
hgpriv hg0 get freq_range
hgpriv hg0 get chan_list
hgpriv hg0 get center_freq
```

Each command prints a `RESP:` status followed by the returned value. `RESP:0` indicates that the command was accepted. The value returned by `center_freq` is in units of 0.1 MHz; for example, `9160` means 916.0 MHz.

## Default configuration

The supplied firmware uses these defaults:

| Parameter | Default value |
| --- | --- |
| Mode | Access point (`ap`) |
| SSID | `oolite-v7-default` |
| Frequency range | `9080,9240,8` |
| Channel bandwidth | 8 MHz |
| Encryption | None (`NONE`) |

With this 8 MHz configuration, the available center frequencies are 908.0, 916.0, and 924.0 MHz. Channel numbers are indexes starting at 1, not frequencies:

| Channel index | Center frequency |
| --- | --- |
| 1 | 908.0 MHz |
| 2 | 916.0 MHz |
| 3 | 924.0 MHz |

## Change settings temporarily

The following example changes the SSID and selects channel 2 (916.0 MHz):

```sh
hgpriv hg0 set ssid=My-HaLow-Network
hgpriv hg0 set channel=2
```

Confirm the result:

```sh
hgpriv hg0 get ssid
hgpriv hg0 get center_freq
```

To define a custom list of center frequencies, use values in units of 0.1 MHz. Up to 16 frequencies are supported:

```sh
hgpriv hg0 set chan_list=9080,9160,9240
hgpriv hg0 set bss_bw=8
hgpriv hg0 set channel=2
```

Alternatively, define a continuous frequency range:

```sh
hgpriv hg0 set freq_range=9080,9240,8
hgpriv hg0 set bss_bw=8
hgpriv hg0 set channel=2
```

`chan_list` has priority over `freq_range`. Do not configure both methods unless you intend the `chan_list` setting to take effect. The bandwidth in `freq_range` must match `bss_bw`. Supported bandwidth values are 1, 2, 4, and 8 MHz.

## Make settings persistent

The driver reads `/etc/hgicf.conf` when the HaLow module starts. Edit this file to make the settings survive a reboot:

```sh
vi /etc/hgicf.conf
```

For example:

```ini
freq_range=9080,9240,8
bss_bw=8
tx_mcs=255
key_mgmt=NONE
ssid=My-HaLow-Network
mode=ap
```

Then reboot the board:

```sh
reboot
```

After the board restarts, reconnect by SSH and use the check commands above to verify the active settings.

The configuration order is important: set the frequency list or range and bandwidth first, then the security and SSID parameters, and set `mode` last. Keep `mode=ap` when the board provides the HaLow network. Use the supplied `ah-mode-switch` command only when intentionally changing between access point and station operation.

## Regulatory notice

Sub-GHz Wi-Fi HaLow frequency allocations and permitted transmit power vary by country or region. Configure only frequencies, bandwidth, and power levels permitted at the deployment location. The other HaLow device must use a compatible frequency list, bandwidth, SSID, and security configuration.

If a required regional frequency plan is not listed in the supplied firmware, contact GainStrong technical support before deployment.
