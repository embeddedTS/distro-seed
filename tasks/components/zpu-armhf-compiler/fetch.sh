#!/bin/bash -xe

TARGET_URL="https://files.embeddedts.com/ts-socket-macrocontrollers/ts-4100-linux/zpu/armhf-zpu-elf-gcc-${DS_MANIFEST_VERSION}.tar.bz2"
HOST_URL="https://files.embeddedts.com/ts-socket-macrocontrollers/ts-4100-linux/zpu/x86_64-zpu-elf-gcc-${DS_MANIFEST_VERSION}.tar.bz2"

install -d "${DS_OVERLAY}/opt/"

echo "${DS_STAGING}"
common/host/fetch_tar.sh "${TARGET_URL}" "${DS_OVERLAY}/opt/"
common/host/fetch_tar.sh "${HOST_URL}" "${DS_STAGING}"
echo "${DS_STAGING}"
