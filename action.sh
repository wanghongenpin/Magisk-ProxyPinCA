#!/system/bin/sh
# This script runs when user presses Action button in root manager
MODDIR=${0%/*}
LOG_FILE="/data/local/tmp/ProxyPinCert.log"
CERT_DIR="$MODDIR/system/etc/security/cacerts"

echo "╔════════════════════════════════════════╗"
echo "║  ProxyPin Certificate Installer v1.0   ║"
echo "║  by firdausmntp                        ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Get API level
API=$(getprop ro.build.version.sdk)
ANDROID_VERSION=$(getprop ro.build.version.release)
echo "- Android: $ANDROID_VERSION (API $API)"

# Check certificate using find (more reliable)
CERT_COUNT=$(find "$CERT_DIR" -maxdepth 1 -type f -name "*.0" 2>/dev/null | wc -l)
CERT_COUNT=$(echo "$CERT_COUNT" | tr -d ' ')

echo "- Certificates in module: $CERT_COUNT"

if [ "$CERT_COUNT" -eq 0 ] || [ -z "$CERT_COUNT" ]; then
    echo ""
    echo "⚠️  CERTIFICATE NOT FOUND!"
    echo ""
    echo "Certificate 243f0bfb.0 is missing."
    echo "Try reinstalling the module."
    echo ""
    exit 1
fi

# Show certificate info
echo ""
echo "Certificates:"
find "$CERT_DIR" -maxdepth 1 -type f -name "*.0" 2>/dev/null | while read cert; do
    name=$(basename "$cert")
    size=$(ls -la "$cert" | awk '{print $5}')
    # Try to get certificate subject
    subject=$(openssl x509 -in "$cert" -noout -subject 2>/dev/null | sed 's/subject=//g' | head -1)
    echo "  - $name ($size bytes)"
    if [ -n "$subject" ]; then
        echo "    Subject: $(echo "$subject" | cut -c1-60)..."
    fi
done

# Check system cacerts
echo ""
echo "System CA Store Status:"
SYSTEM_CERT=$(find "$CERT_DIR" -maxdepth 1 -type f -name "*.0" 2>/dev/null | head -1 | xargs basename 2>/dev/null)

if [ -n "$SYSTEM_CERT" ]; then
    if [ -f "/system/etc/security/cacerts/$SYSTEM_CERT" ]; then
        echo "  ✓ $SYSTEM_CERT present in /system/etc/security/cacerts"
    else
        echo "  ✗ $SYSTEM_CERT NOT in /system/etc/security/cacerts (Magic Mount may not be active yet)"
    fi
fi

# Check APEX status on Android 14+
if [ "$API" -ge 34 ]; then
    echo ""
    echo "Android 14+ APEX Status:"
    APEX_DIR="/apex/com.android.conscrypt/cacerts"

    if [ -d "$APEX_DIR" ]; then
        find "$CERT_DIR" -maxdepth 1 -type f -name "*.0" 2>/dev/null | while read cert; do
            name=$(basename "$cert")
            if [ -f "$APEX_DIR/$name" ]; then
                echo "  ✓ $name present in APEX"
            else
                echo "  ✗ $name NOT in APEX (needs re-injection or reboot)"
            fi
        done

        echo ""
        APEX_COUNT=$(find "$APEX_DIR" -maxdepth 1 -name "*.0" -type f 2>/dev/null | wc -l)
        echo "  Total certs in APEX: $APEX_COUNT"
    else
        echo "  APEX CA directory not found"
    fi
else
    echo ""
    echo "Note: Standard Magic Mount is used for Android < 14"
fi

# Check Trusted Credentials hint
echo ""
echo "📱 How to verify:"
echo "   Settings → Security → Encryption & credentials"
echo "   → Trusted credentials → System"
echo "   Look for: ProxyPin CA"

# Option to re-inject
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Options:"
echo "  1. Re-inject certificates (for Android 14+ APEX)"
echo "  2. View logs"
echo "  3. Force reboot"
echo "  4. Exit"
echo ""
read -p "Select option [1-4]: " choice

case "$choice" in
    1)
        echo ""
        echo "Running certificate re-injection..."
        sh "$MODDIR/service.sh"
        echo ""
        echo "Done! Please check:"
        echo "  - Settings → Security → Trusted credentials → System"
        echo "  - ProxyPin app should detect the certificate"
        ;;
    2)
        echo ""
        echo "=== Recent Logs ==="
        tail -50 "$LOG_FILE" 2>/dev/null || echo "No logs found"
        ;;
    3)
        echo ""
        echo "Rebooting device..."
        reboot
        ;;
    4)
        echo "Goodbye!"
        ;;
    *)
        echo "Invalid option"
        ;;
esac

if [ "$KSU" = "true" ] || [ "$APATCH" = "true" ]; then
    echo ""
    echo "Dialog will close in 10 seconds..."
    sleep 10
fi
