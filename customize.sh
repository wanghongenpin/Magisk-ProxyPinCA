#!/system/bin/sh
# Android 5.0 - 16 (API 21-36) compatible
SKIPUNZIP=0

#################
# Helper Functions
#################

print_banner() {
    ui_print "╔════════════════════════════════════════╗"
    ui_print "║  ProxyPin Certificate Installer v1.0   ║"
    ui_print "║  by firdausmntp                        ║"
    ui_print "╚════════════════════════════════════════╝"
    ui_print ""
}

detect_root_solution() {
    if [ "$KSU" = "true" ]; then
        # Check for SukiSU specifically
        if [ -f /data/adb/ksu/bin/ksud ]; then
            if strings /data/adb/ksu/bin/ksud 2>/dev/null | grep -qi "sukisu"; then
                ROOT_IMPL="SukiSU"
            else
                ROOT_IMPL="KernelSU"
            fi
        else
            ROOT_IMPL="KernelSU"
        fi
        ROOT_VER="$KSU_VER"
        ROOT_VER_CODE="$KSU_VER_CODE"
    elif [ "$APATCH" = "true" ]; then
        ROOT_IMPL="APatch"
        ROOT_VER="$APATCH_VER"
        ROOT_VER_CODE="$APATCH_VER_CODE"
    else
        ROOT_IMPL="Magisk"
        ROOT_VER="$MAGISK_VER"
        ROOT_VER_CODE="$MAGISK_VER_CODE"
    fi
}

#################
# Compatibility Check
#################

check_compatibility() {
    # Check API level
    API=$(getprop ro.build.version.sdk)
    [ -z "$API" ] && API=21

    if [ "$API" -lt 21 ]; then
        abort "! ERROR: Minimum Android 5.0 (API 21) required!"
    fi

    if [ "$API" -gt 36 ]; then
        ui_print "! WARNING: Untested Android version (API $API)"
        ui_print "  Proceeding anyway..."
    fi

    # Root solution version checks
    case "$ROOT_IMPL" in
        "Magisk")
            [ "$ROOT_VER_CODE" -lt 20400 ] && abort "! ERROR: Magisk v20.4+ required!"
            ;;
        "KernelSU"|"SukiSU")
            if [ "$ROOT_VER_CODE" -lt 10000 ]; then
                ui_print "! WARNING: Old $ROOT_IMPL version"
            fi
            ;;
        "APatch")
            if [ "$ROOT_VER_CODE" -lt 10300 ]; then
                ui_print "! WARNING: Old APatch version"
            fi
            ;;
    esac
}

#################
#################

setup_permissions() {
    ui_print "- Setting permissions..."

    # System certificate directory
    if [ -d "$MODPATH/system/etc/security/cacerts" ]; then
        set_perm_recursive "$MODPATH/system/etc/security/cacerts" 0 0 0755 0644
    fi

    # Scripts
    for script in post-fs-data.sh service.sh uninstall.sh action.sh; do
        [ -f "$MODPATH/$script" ] && set_perm "$MODPATH/$script" 0 0 0755
    done

    # WebUI
    if [ -d "$MODPATH/webroot" ]; then
        set_perm_recursive "$MODPATH/webroot" 0 0 0755 0644
    fi
}

cleanup_certificates() {
    ui_print "- Cleaning up non-certificate files..."

    local CERT_DIR="$MODPATH/system/etc/security/cacerts"

    # Remove README.md if exists
    if [ -f "$CERT_DIR/README.md" ]; then
        rm -f "$CERT_DIR/README.md"
        ui_print "  Removed README.md"
    fi

    # Remove .gitkeep if exists
    if [ -f "$CERT_DIR/.gitkeep" ]; then
        rm -f "$CERT_DIR/.gitkeep"
        ui_print "  Removed .gitkeep"
    fi

    # Remove any other non-.0 files that might cause issues
    for file in "$CERT_DIR"/*; do
        if [ -f "$file" ]; then
            case "$(basename "$file")" in
                *.0)
                    # Valid certificate, keep it
                    ;;
                *)
                    # Non-certificate file, remove it
                    rm -f "$file"
                    ui_print "  Removed $(basename "$file")"
                    ;;
            esac
        fi
    done
}

check_certificate() {
    local cert_dir="$MODPATH/system/etc/security/cacerts"
    local cert_count=$(find "$cert_dir" -maxdepth 1 -type f -name "*.0" 2>/dev/null | wc -l)
    cert_count=$(echo "$cert_count" | tr -d ' ')  # Remove whitespace

    if [ "$cert_count" -eq 0 ] || [ -z "$cert_count" ]; then
        ui_print ""
        ui_print "╔════════════════════════════════════════╗"
        ui_print "║  ⚠️  CERTIFICATE NOT FOUND!             ║"
        ui_print "╚════════════════════════════════════════╝"
        ui_print ""
        ui_print "! Certificate 243f0bfb.0 was not extracted."
        ui_print "! Try reinstalling the module."
        ui_print ""
    else
        ui_print "✓ Found $cert_count certificate(s)"
        # List certificates
        find "$cert_dir" -maxdepth 1 -type f -name "*.0" 2>/dev/null | while read cert; do
            ui_print "  - $(basename "$cert")"
        done
    fi
}

setup_android14_plus() {
    API=$(getprop ro.build.version.sdk)

    if [ "$API" -ge 34 ]; then
        ui_print "- Android 14+ detected (API $API)"
        ui_print "- APEX CA bypass will be configured"

        # Ensure scripts are properly configured for APEX
        chmod 0755 "$MODPATH/post-fs-data.sh" 2>/dev/null
        chmod 0755 "$MODPATH/service.sh" 2>/dev/null
    fi
}

print_summary() {
    ui_print ""
    ui_print "╔════════════════════════════════════════╗"
    ui_print "║  ✓ Installation Complete!              ║"
    ui_print "╚════════════════════════════════════════╝"
    ui_print ""
    ui_print "  Root Solution: $ROOT_IMPL ($ROOT_VER)"
    ui_print "  Android API:   $API"
    ui_print ""
    ui_print "  ⚡ Actions:"
    ui_print "    • Reboot your device"
    ui_print "    • Check: Settings → Security → Trusted credentials"
    ui_print ""

    if [ "$API" -ge 34 ]; then
        ui_print "  📱 Android 14+ Notes:"
        ui_print "    • APEX bypass runs automatically"
        ui_print "    • Check ProxyPin after reboot"
        ui_print ""
    fi

    ui_print "  📋 Logs: /data/local/tmp/ProxyPinCert.log"
    ui_print ""

# Installation
    ui_print "  GitHub: https://github.com/firdausmntp/ProxyPin-cert-installer"
    ui_print ""
}

#################
# Main
#################

print_banner
detect_root_solution

ui_print "- Detected: $ROOT_IMPL"
ui_print "- Version:  $ROOT_VER (code: $ROOT_VER_CODE)"
ui_print ""

check_compatibility
setup_permissions
cleanup_certificates
check_certificate
setup_android14_plus
print_summary