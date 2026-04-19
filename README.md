# 📱 ProxyPin Certificate Installer

<p align="center">
  <img src="https://img.shields.io/badge/Version-v1.0-blue?style=for-the-badge" alt="Version"/>
  <img src="https://img.shields.io/badge/Android-5.0--15-green?style=for-the-badge&logo=android" alt="Android"/>
  <img src="https://img.shields.io/badge/License-GPL--3.0-yellow?style=for-the-badge" alt="License"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Magisk-20.4%2B-00AF9C?style=flat-square&logo=magisk" alt="Magisk"/>
  <img src="https://img.shields.io/badge/KernelSU-Supported-orange?style=flat-square" alt="KernelSU"/>
  <img src="https://img.shields.io/badge/SukiSU-✓%20Tested-9333ea?style=flat-square" alt="SukiSU"/>
  <img src="https://img.shields.io/badge/APatch-Supported-blue?style=flat-square" alt="APatch"/>
</p>

<p align="center">
  <b>📱 Install ProxyPin CA Certificate to System CA Store</b><br>
  <sub>Tested on Android 15 with SukiSU v40201</sub>
</p>

---

## 📋 Description

This Magisk/KernelSU/APatch module installs the **ProxyPin CA Certificate** (`243f0bfb.0`) into the Android System CA Store, enabling HTTPS traffic interception with the [ProxyPin](https://github.com/wanghongenpin/network_proxy_flutter) app.

> ✅ **Certificate is pre-included** in this module. Just install, reboot, and you're done!

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🔧 **Multi-Root Support** | Works with Magisk, KernelSU, SukiSU, APatch |
| 📱 **Wide Android Support** | Android 5.0 - 15 (API 21-35) |
| 🔓 **APEX Bypass** | Proper injection for Android 14+ conscrypt APEX |
| 🖥️ **WebUI Interface** | Monitor status and manage module visually |
| 🛡️ **SELinux Compatible** | Works with SELinux enforcing |
| 💾 **Systemless** | Does not modify /system partition |
| 📦 **Pre-included Cert** | Certificate `243f0bfb.0` included, no manual steps |

---

## 📱 Tested Compatibility

### ✅ Verified Working

| Device | Android | Root | Status |
|--------|---------|------|--------|
| Redmi Note 8 Pro | 15 (API 35) | SukiSU v40201 | ✅ **Tested** |

### Root Solutions Support

| Solution | Status | Notes |
|----------|--------|-------|
| **SukiSU** | ✅ Tested | Fully working with WebUI |
| **KernelSU** | ✅ Supported | With WebUI support |
| **Magisk** | ✅ Supported | v20.4+ required |
| **APatch** | ✅ Supported | v10300+ required |

### Android Versions

| Version | API | Status |
|---------|-----|--------|
| Android 5.0 - 13 | 21-33 | ✅ Standard Magic Mount |
| Android 14 | 34 | ✅ APEX Bypass |
| Android 15 | 35 | ✅ APEX Bypass (Tested) |

---

## 🚀 Quick Start

### Step 1: Install Module

1. Download `ProxyPin-Cert-Installer-v1.0.zip`
2. Install via **Magisk/KernelSU/SukiSU/APatch** Manager
3. **Reboot** device

### Step 2: Verify

1. Go to **Settings** → **Security** → **Trusted credentials** → **System**
2. Look for **ProxyPin CA** certificate
3. Open ProxyPin and start capturing

> 💡 The certificate (`243f0bfb.0`) is already pre-included in the module. No export or manual copy needed.

---

## 🖥️ WebUI Features

Access WebUI through your root manager's module settings:

| Feature | Description |
|---------|-------------|
| 📊 **Status Monitor** | View module and APEX injection status |
| 💉 **Re-inject** | Manually trigger certificate injection |
| 📋 **View Logs** | Check module operation logs |
| 🔄 **Reboot** | Quick reboot to apply changes |

---

## 🔧 Android 14+ APEX Bypass

Starting Android 14, CA certificates moved to APEX module (`com.android.conscrypt`).

This module implements:
- **Namespace Injection** - Mounts into zygote namespaces
- **Dynamic Re-injection** - Service script reinjects after boot
- **Per-process Mount** - All app processes see the certificate

### Verify Injection
```bash
# Check if certificate is in APEX
ls /apex/com.android.conscrypt/cacerts/*.0 | head -5

# View module logs
cat /data/local/tmp/ProxyPinCert.log
```

---

## ⚠️ Troubleshooting

### "Certificate Not Installed" in ProxyPin

```bash
# 1. Check logs
cat /data/local/tmp/ProxyPinCert.log

# 2. Manual re-inject
su -c "sh /data/adb/modules/proxypin-cert-installer/post-fs-data.sh"

# 3. Force stop and reopen ProxyPin
```

### "Unknown Publisher" Error

- **SukiSU/KernelSU**: Settings → Enable "Allow untrusted modules"
- **APatch**: Settings → Security → Enable "Allow unknown sources"

### WebUI Not Loading

1. Ensure `webroot/index.html` exists in module
2. Check if root manager supports WebUI
3. Try reinstalling module

---

## 📁 Module Structure

```
proxypin-cert-installer/
├── META-INF/com/google/android/
│   ├── update-binary
│   └── updater-script
├── system/etc/security/cacerts/
│   └── 243f0bfb.0              # ProxyPin CA cert (pre-included)
├── webroot/
│   └── index.html            # WebUI
├── module.prop
├── customize.sh               # Installation script
├── post-fs-data.sh            # APEX injection
├── service.sh                 # Post-boot injection
├── action.sh                  # Action button handler
└── uninstall.sh               # Cleanup script
```

---

## 📝 Changelog

### v1.0 (Current)
- ✅ Initial release
- ✅ Certificate pre-included (`243f0bfb.0`)
- ✅ Multi-root support (Magisk/KernelSU/SukiSU/APatch)
- ✅ Android 5.0-15+ support
- ✅ APEX CA bypass for Android 14+
- ✅ WebUI for status monitoring
- ✅ SELinux enforcing compatible
- ✅ GitHub Actions CI/CD

## 📄 License

GPL-3.0 License - See [LICENSE](LICENSE) for details.

---

## 🙏 Credits

- **[firdausmntp](https://github.com/firdausmntp)** - Author & Maintainer
- [wanghongenpin](https://github.com/wanghongenpin/network_proxy_flutter) - ProxyPin App
- [topjohnwu](https://github.com/topjohnwu) - Magisk Framework
- [tiann](https://github.com/tiann) - KernelSU Framework
- [pomelohan](https://github.com/pomelohan/SukiSU-Ultra) - SukiSU Framework
- [bmax121](https://github.com/bmax121) - APatch Framework

---

## 🔗 Links

[![GitHub](https://img.shields.io/badge/GitHub-Repository-181717?style=for-the-badge&logo=github)](https://github.com/firdausmntp/ProxyPin-cert-installer)
[![Issues](https://img.shields.io/badge/Report-Issues-red?style=for-the-badge&logo=github)](https://github.com/firdausmntp/ProxyPin-cert-installer/issues)
[![ProxyPin](https://img.shields.io/badge/ProxyPin-Website-blue?style=for-the-badge)](https://github.com/wanghongenpin/network_proxy_flutter)
