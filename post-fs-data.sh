#!/system/bin/sh


exec > /data/local/tmp/ProxyPinCA.log
exec 2>&1

#set -x

MODDIR=${0%/*}

set_context() {
    [ "$(getenforce)" = "Enforcing" ] || return 0

    default_selinux_context=u:object_r:system_file:s0
    selinux_context=$(ls -Zd $1 | awk '{print $1}')

    if [ -n "$selinux_context" ] && [ "$selinux_context" != "?" ]; then
        chcon -R $selinux_context $2
    else
        chcon -R $default_selinux_context $2
    fi
}

#LOG_PATH="/data/local/tmp/ProxyPinCA.log"
echo "[$(date +%F) $(date +%T)] - ProxyPinCA post-fs-data.sh start."
chown -R 0:0 ${MODDIR}/system/etc/security/cacerts
if [ -d /apex/com.android.conscrypt/cacerts ]; then
    # 检测到 android 14 以上，存在该证书目录
    CERT_HASH=243f0bfb

    CERT_FILE=${MODDIR}/system/etc/security/cacerts/${CERT_HASH}.0
    echo "[$(date +%F) $(date +%T)] - CERT_FILE: ${CERT_FILE}"
    if ! [ -e "${CERT_FILE}" ]; then
        echo "[$(date +%F) $(date +%T)] - ProxyPinCA certificate not found."
        exit 0
    fi

    TEMP_DIR=/data/local/tmp/cacerts-copy
    rm -rf "$TEMP_DIR"
    mkdir -p -m 700 "$TEMP_DIR"
    mount -t tmpfs tmpfs "$TEMP_DIR"

    # 复制证书到临时目录
    cp -f /apex/com.android.conscrypt/cacerts/* "$TEMP_DIR"
    cp -f $CERT_FILE "$TEMP_DIR"

    chown -R 0:0 "$TEMP_DIR"
    set_context /apex/com.android.conscrypt/cacerts "$TEMP_DIR"

    # 检查新证书是否成功添加
    CERTS_NUM="$(ls -1 "$TEMP_DIR" | wc -l)"
    if [ "$CERTS_NUM" -gt 10 ]; then
        mount -o bind "$TEMP_DIR" /apex/com.android.conscrypt/cacerts
         for pid in 1 $(pgrep zygote) $(pgrep zygote64); do
            nsenter --mount=/proc/${pid}/ns/mnt -- \
                mount --bind "$TEMP_DIR" /apex/com.android.conscrypt/cacerts
        done
        echo "[$(date +%F) $(date +%T)] - $CERTS_NUM Mount success!"
    else
        echo "[$(date +%F) $(date +%T)] - $CERTS_NUM Mount failed!"
    fi

    # 卸载临时目录
    umount "$TEMP_DIR"
    rmdir "$TEMP_DIR"
else
    echo "[$(date +%F) $(date +%T)] - Android version lower than 14 detected"
    set_context /system/etc/security/cacerts ${MODDIR}/system/etc/security/cacerts 
    echo "[$(date +%F) $(date +%T)] - Mount success!"
fi