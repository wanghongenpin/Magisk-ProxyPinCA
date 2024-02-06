#!/system/bin/sh

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

LOG_PATH="/data/local/tmp/ProxyPinCA.log"
echo "[$(date +%F) $(date +%T)] - ProxyPinCA post-fs-data.sh start." > $LOG_PATH

if [ -d /apex/com.android.conscrypt/cacerts ]; then
    # 检测到 android 14 以上，存在该证书目录
    MODDIR=${0%/*}

    TEMP_DIR=/data/local/tmp/cacerts-copy
    rm -rf "$TEMP_DIR"
    mkdir -p -m 700 "$TEMP_DIR"
    mount -t tmpfs tmpfs "$TEMP_DIR"

    # 复制证书到临时目录
    cp -f /apex/com.android.conscrypt/cacerts/* "$TEMP_DIR"

    for file in ./system/etc/security/cacerts/*; do
        CERT_FILE="${MODDIR}/${file}"
        echo "[$(date +%F) $(date +%T)] - CERT_FILE: ${CERT_FILE}" >> $LOG_PATH
        if [ -e "${CERT_FILE}" ]; then
            chmod 644 $CERT_FILE
            chown root:root $CERT_FILE
            cp -f $CERT_FILE "$TEMP_DIR"
        else
            echo "[$(date +%F) $(date +%T)] - ProxyPinCA certificate ${CERT_HASH} not found." >> $LOG_PATH
        fi
    done

    chown -R 0:0 "$TEMP_DIR"
    set_context /apex/com.android.conscrypt/cacerts "$TEMP_DIR"

    # 检查新证书是否成功添加
    CERTS_NUM="$(ls -1 $TEMP_DIR | wc -l)"
    if [ "$CERTS_NUM" -gt 10 ]; then # 假设至少需要有11个证书才算成功
        mount -o bind "$TEMP_DIR" /apex/com.android.conscrypt/cacerts
        echo "[$(date +%F) $(date +%T)] - $CERTS_NUM Mount success!" >> $LOG_PATH
    else
        echo "[$(date +%F) $(date +%T)] - $CERTS_NUM Mount failed!" >> $LOG_PATH
    fi

    # 卸载临时目录
    umount "$TEMP_DIR"
    rmdir "$TEMP_DIR"
else
    echo "[$(date +%F) $(date +%T)] - /apex/com.android.conscrypt/cacerts not exists." >> $LOG_PATH
fi
