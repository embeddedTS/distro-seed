#!/bin/bash -xe

TARGET_URL="https://files.embeddedts.com/ts-socket-macrocontrollers/ts-4100-linux/zpu/armhf-zpu-elf-gcc-3.4.2.tar.bz2"
HOST_URL="https://files.embeddedts.com/ts-socket-macrocontrollers/ts-4100-linux/zpu/x86_64-zpu-elf-gcc-3.4.2.tar.bz2"

install -d "${DS_OVERLAY}/opt/"

echo "${DS_WORK}"
common/host/fetch_tar.sh "${TARGET_URL}" "${DS_OVERLAY}/opt/"
common/host/fetch_tar.sh "${HOST_URL}" "${DS_WORK}"
echo "${DS_WORK}"
