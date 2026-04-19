# Changelog

All notable changes to this project will be documented in this file.

## [v1.0] - 2026-04-16

### Added
- Initial release
- ProxyPin CA certificate (`243f0bfb.0`) pre-included in module
- Install certificate to System CA Store automatically
- Multi-root support: Magisk, KernelSU, SukiSU, APatch
- Android 5.0 - 15+ (API 21-36) compatibility
- APEX CA bypass for Android 14+ (conscrypt module injection)
- Namespace injection into zygote processes
- Dynamic re-injection via service script after boot
- Per-process mount for all app processes
- WebUI for status monitoring (APEX status, logs, reboot)
- Action button handler for root managers
- SELinux enforcing compatible
- Comprehensive logging to `/data/local/tmp/ProxyPinCert.log`
- Uninstall cleanup script (unmount APEX, remove temp files)
- GitHub Actions CI/CD for automated builds and releases
