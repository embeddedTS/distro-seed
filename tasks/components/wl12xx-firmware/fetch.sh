#!/bin/bash -e

URL="https://files.embeddedts.com/ts-arm-sbc/ts-7970-linux/wifi-firmware/wl12xx-firmware-20170113.tar.xz"
VERSION="20170113"
install -d "$DS_OVERLAY/lib/firmware/"
install -d "$DS_OVERLAY_CONTROL"
printf '%s\n' "$VERSION" > "$DS_OVERLAY_CONTROL/version"
common/host/fetch_tar.sh "$URL" "$DS_OVERLAY/lib/firmware/"
