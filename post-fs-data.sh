#!/system/bin/sh

if [ -d /apex/com.android.conscrypt/cacerts ]; then
    # 检测到 android 14 以上，存在该证书目录
    CERT_HASH=243f0bfb
    MODDIR=${0%/*}
    NEW_CERT_FILE=${MODDIR}/system/etc/security/cacerts/${CERT_HASH}.0
    LOG_PATH="/cache/ProxyPinCA.log"
    echo "Found /apex/com.android.conscrypt/cacerts." >> ${LOG_PATH}
    echo "Adding new certificate to /apex/com.android.conscrypt/cacerts." >> ${LOG_PATH}

    # 创建一个临时目录
    TEMP_DIR="/data/local/tmp/proxypin-ca-certs"
    mkdir -p "$TEMP_DIR"

    # 挂载临时文件系统
    mount -t tmpfs tmpfs "$TEMP_DIR"

    # 复制原始证书到临时目录
    cp -f /apex/com.android.conscrypt/cacerts/* "$TEMP_DIR"

    # 添加新证书到临时目录
    cp -f "$NEW_CERT_FILE" "$TEMP_DIR"

    # 检查新证书是否成功添加
    if [ -f "$TEMP_DIR/$(basename "$NEW_CERT_FILE")" ]; then
        # 如果新证书成功添加，则挂载回原始目录
        mount --bind "$TEMP_DIR" /apex/com.android.conscrypt/cacerts
        echo "Mount success!" >> ${LOG_PATH}
    else
        echo "Failed to add new certificate." >> ${LOG_PATH}
    fi

    # 卸载临时目录
    umount "$TEMP_DIR"
    rmdir "$TEMP_DIR"
else
    echo "/apex/com.android.conscrypt/cacerts not exists." >> ${LOG_PATH}
fi