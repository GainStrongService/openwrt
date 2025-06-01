# Upgrade Notes

## Kernel and Base System
- Repository is prepared for kernel 6.1 and OpenWrt r24101.
- Device definition moved to ath79 DTS `oolite-v1.dts`.

## SPS Agent
- Added local `sps-agent` package placeholder with Lua script.
- Enabled via `CONFIG_PACKAGE_sps-agent=y` in `Oolite-V1.0.config`.

## Known Limitations
- Upstream tag `v24.10.1` could not be fetched due to network restrictions.
- `sps-agent` package contains placeholder implementation.

