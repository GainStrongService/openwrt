# GainStrong OpenWrt Product Support

This repository provides OpenWrt source branches for GainStrong WiFi modules
and router products.

Branch names generally follow:

```text
<OpenWrt version>/<platform-or-soc>-<product>
```

## Supported Products

| Product | OpenWrt Versions | Branches | Status / Notes |
| --- | --- | --- | --- |
| Minibox V2.0 | 22.03, 25.12 | [22.03](https://github.com/GainStrongService/openwrt/tree/2203/MT7628-Minibox-V2.0)<br>[25.12](https://github.com/GainStrongService/openwrt/tree/2512/MT76x8-Minibox-V2) | Supported |
| Minibox V3.X | 19.07, 22.03 | [19.07](https://github.com/GainStrongService/openwrt/tree/1907/qca9531-oolite-v5.x-minibox-v3.x)<br>[22.03 V3.0](https://github.com/GainStrongService/openwrt/tree/2203/QCA9531-MiniBox-V3.0)<br>[22.03 V3.X](https://github.com/GainStrongService/openwrt/tree/2203/QCA9531-MiniBox-V3.X) | Supported |
| Minibox V5.0 | 25.12 | [25.12](https://github.com/GainStrongService/openwrt/tree/2512/MT7981-Minibox-V5.0) | Supported |
| Minibox LTE | 22.03, 23.05 | [22.03](https://github.com/GainStrongService/openwrt/tree/2203/QCA9531-MiniBox-LTE)<br>[23.05](https://github.com/GainStrongService/openwrt/tree/2305/QCA9531-MiniBox-LTE) | Supported |
| Minibox LoRa | ESP32 SDK | [SDK](https://github.com/GainStrongService/Minibox-LoRa-SDK) | Supported |
| Oolite V1.0 | 21.02, 22.03, 23.05, 24.10 | [21.02](https://github.com/GainStrongService/openwrt/tree/2102/ar9331-oolite1)<br>[22.03](https://github.com/GainStrongService/openwrt/tree/2203/AR9331-Oolite-V1.X)<br>[23.05](https://github.com/GainStrongService/openwrt/tree/2305/AR9331-Oolite-V1.0)<br>[24.10](https://github.com/GainStrongService/openwrt/tree/2410/AR9331-Oolite-V1.0) | Supported |
| Oolite V3.X | 21.02, 22.03, 23.05, 24.10 | [21.02](https://github.com/GainStrongService/openwrt/tree/2102/mt76x8-oolite-v3.x)<br>[22.03 V3.2](https://github.com/GainStrongService/openwrt/tree/2203/MT7628-Oolite-V3.2)<br>[22.03 V3.4](https://github.com/GainStrongService/openwrt/tree/2203/MT76x8-Oolite-V3.4)<br>[23.05 V3.3](https://github.com/GainStrongService/openwrt/tree/2305/MT76x8-Oolite-V3.3)<br>[23.05 V3.4](https://github.com/GainStrongService/openwrt/tree/2305/MT76x8-Oolite-V3.4)<br>[24.10](https://github.com/GainStrongService/openwrt/tree/2410/MT76x8-Oolite-V3.X) | Supported |
| Oolite V5.X | 18.06, 19.07, 21.02 | [18.06](https://github.com/GainStrongService/openwrt/tree/1806/qca9531-oolite-5)<br>[19.07](https://github.com/GainStrongService/openwrt/tree/1907/qca9531-oolite-v5.x-minibox-v3.x)<br>[21.02](https://github.com/GainStrongService/openwrt/tree/2102/qca9531-oolite5-minibox3) | Supported |
| Oolite V8.X / V8.2 | 15.05, 19.07, 21.02, 22.03, 23.05 | [15.05](https://github.com/GainStrongService/openwrt/tree/1505/mt7621-oolite8)<br>[19.07](https://github.com/GainStrongService/openwrt/tree/1907/mt7621-oolite8)<br>[21.02](https://github.com/GainStrongService/openwrt/tree/2102/mt7621-oolite-v8.x)<br>[22.03 V8.X](https://github.com/GainStrongService/openwrt/tree/2203/MT7621-Oolite-V8.X)<br>[22.03 V8.2](https://github.com/GainStrongService/openwrt/tree/2203/MT7621-Oolite-V8.2)<br>[23.05 V8.2](https://github.com/GainStrongService/openwrt/tree/2305/MT7621-Oolite-V8.2) | Supported |
| Oolite V9.0 | 22.03 | [22.03](https://github.com/GainStrongService/openwrt/tree/2203/AR9344-Oolite-V9.0) | Supported |
| OoliteBox V1.0 | 22.03 | [22.03](https://github.com/GainStrongService/openwrt/tree/2203/QCA9531-OoliteBox-V1.0) | Supported |
| Oolite-IPQ4019 | 22.03 | [22.03](https://github.com/GainStrongService/openwrt/tree/2203/Oolite-IPQ4019) | Supported |
| Oolite-MT7620A | 22.03 | [22.03](https://github.com/GainStrongService/openwrt/tree/2203/Oolite-MT7620) | Supported |
| Oolite-MT7981B V1 | 23.05, 24.10 | [23.05](https://github.com/GainStrongService/openwrt/tree/2305/Oolite-MT7981B-V1)<br>[24.10](https://github.com/GainStrongService/openwrt/tree/2410/Oolite-MT7981B-V1) | Supported |
| Oolite-MT7987A | 25.12 | [25.12](https://github.com/GainStrongService/openwrt/tree/2512/Oolite-MT7987A) | Supported |
| CeilingAP-V1 | 21.02 | [21.02](https://github.com/GainStrongService/openwrt/tree/2102/qca9531-CeilingAP-V1-QCA9886) | Supported |
| GS-4GR11 | 22.03 | [22.03](https://github.com/GainStrongService/openwrt/tree/2203/MT7628-GS-4GR11) | Supported |
| RM03-4G | 21.02 | [21.02](https://github.com/GainStrongService/openwrt/tree/2102/mt7620-rm03) | Supported |
