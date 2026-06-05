#!/bin/bash -e

install -d "$DS_OVERLAY/etc/systemd/system"
install -m 0644 "$DS_TASK_PATH/files/weston-kiosk.service" \
	"$DS_OVERLAY/etc/systemd/system/weston-kiosk.service"

install -d "$DS_OVERLAY/etc/xdg/weston"
cat > "$DS_OVERLAY/etc/xdg/weston/weston.ini" <<EOF
[core]
shell=kiosk-shell.so

[autolaunch]
path=$CONFIG_DS_WESTON_KIOSK_SERVICE_COMMAND
watch=true
EOF
chmod 0644 "$DS_OVERLAY/etc/xdg/weston/weston.ini"

install -d "$DS_OVERLAY/usr/local/bin"
install -m 0755 "$DS_TASK_PATH/files/weston-kiosk.sh" \
	"$DS_OVERLAY/usr/local/bin/weston-kiosk.sh"
