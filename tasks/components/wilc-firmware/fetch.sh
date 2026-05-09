#!/bin/bash -e

WILC_TAG="wilc_linux_${DS_MANIFEST_VERSION//./_}"
URL="https://github.com/linux4wilc/firmware/archive/refs/tags/${WILC_TAG}.tar.gz"

install -d "$DS_OVERLAY/lib/firmware/mchp/"

common/host/fetch_tar.sh "$URL" "${DS_TASK_WORK}"

install -m 644 "${DS_TASK_WORK}/firmware-${WILC_TAG}/wilc3000_ble_firmware.bin" "$DS_OVERLAY/lib/firmware/mchp/"
install -m 644 "${DS_TASK_WORK}/firmware-${WILC_TAG}/wilc3000_wifi_firmware.bin" "$DS_OVERLAY/lib/firmware/mchp/"
install -m 644 "${DS_TASK_WORK}/firmware-${WILC_TAG}/LICENSE.wilc_fw" "$DS_OVERLAY/lib/firmware/mchp/"
