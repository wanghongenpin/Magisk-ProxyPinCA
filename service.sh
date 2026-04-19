#!/system/bin/sh
# ProxyPin Certificate Installer - Service Script
# Runs after boot to ensure APEX injection persists for all apps

MODDIR=${0%/*}
LOG_FILE="/data/local/tmp/ProxyPinCert.log"
CERT_DIR="${MODDIR}/system/etc/security/cacerts"
TEMP_DIR="/data/local/tmp/proxypin-apex-ca"
APEX_CACERTS="/apex/com.android.conscrypt/cacerts"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [service] $1" >> "$LOG_FILE"
}

log ""
log "══════════════════════════════════════════════════════"
log "Service script started"

API=$(getprop ro.build.version.sdk)
log "Android API: $API"

# Wait for boot
count=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ $count -lt 60 ]; do
    sleep 1
    count=$((count + 1))
done
log "Boot completed (${count}s)"

# Skip for Android < 14
if [ "$API" -lt 34 ]; then
    log "Android < 14, skipping"
    exit 0
fi

# Find our cert
CERT_FILE=$(find "$CERT_DIR" -maxdepth 1 -type f -name "*.0" 2>/dev/null | head -1)
CERT_NAME=$(basename "$CERT_FILE" 2>/dev/null)

if [ -z "$CERT_NAME" ]; then
    log "ERROR: No certificate found"
    exit 1
fi

log "Certificate: $CERT_NAME"

# Check if already mounted correctly
if [ -f "$APEX_CACERTS/$CERT_NAME" ]; then
    log "✓ Certificate already in APEX"
else
    log "Certificate not in APEX, re-injecting..."
    
    # Ensure tmpfs is mounted
    if ! mountpoint -q "$TEMP_DIR" 2>/dev/null; then
        mkdir -p "$TEMP_DIR"
        mount -t tmpfs tmpfs "$TEMP_DIR"
        cp -a "$APEX_CACERTS"/* "$TEMP_DIR/" 2>/dev/null
        cp -f "$CERT_FILE" "$TEMP_DIR/"
        chown -R 0:0 "$TEMP_DIR"
        chmod 755 "$TEMP_DIR"
        chmod 644 "$TEMP_DIR"/*
        
        APEX_CONTEXT=$(ls -Zd "$APEX_CACERTS" 2>/dev/null | awk '{print $1}')
        [ -n "$APEX_CONTEXT" ] && chcon -R "$APEX_CONTEXT" "$TEMP_DIR" 2>/dev/null
    fi
    
    # Mount globally
    mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null
    nsenter --mount=/proc/1/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null
fi

# CRITICAL: Mount in all zygote namespaces
# This ensures ALL apps can see the certificate
log "Injecting to zygote namespaces..."

for zygote in zygote zygote64; do
    PID=$(pidof "$zygote" 2>/dev/null)
    if [ -n "$PID" ]; then
        nsenter --mount=/proc/$PID/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null
        log "  $zygote (PID $PID)"
    fi
done

# Also inject to Settings app (for Trusted Credentials visibility)
SETTINGS_PID=$(pidof com.android.settings 2>/dev/null)
if [ -n "$SETTINGS_PID" ]; then
    nsenter --mount=/proc/$SETTINGS_PID/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null
    log "  Settings app (PID $SETTINGS_PID)"
fi

# Inject to ProxyPin if running
PROXYPIN_PID=$(pidof com.proxy.pin 2>/dev/null)
if [ -z "$PROXYPIN_PID" ]; then
    # Try alternative package names
    PROXYPIN_PID=$(pidof com.network.proxy 2>/dev/null)
fi
if [ -n "$PROXYPIN_PID" ]; then
    nsenter --mount=/proc/$PROXYPIN_PID/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null
    log "  ProxyPin app (PID $PROXYPIN_PID)"
fi

# Final verification
sleep 2
if [ -f "$APEX_CACERTS/$CERT_NAME" ]; then
    log "✓ SUCCESS: Certificate in APEX"
else
    log "✗ Certificate may not be visible to all apps"
fi

# Count
APEX_COUNT=$(ls -1 "$APEX_CACERTS"/*.0 2>/dev/null | wc -l)
log "APEX certificates: $APEX_COUNT"

log ""
log "Service completed"
log "══════════════════════════════════════════════════════"
