#!/system/bin/sh

SKIPUNZIP=0

ASH_STANDALONE=0

ui_print "开始安装模块"

ui_print "提取模块证书"

unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2

ui_print "安装成功,重启手机后去系统证书查看ProxyPinCA是否生效."

ui_print " "

set_perm_recursive $MODPATH 0 0 0755 0644