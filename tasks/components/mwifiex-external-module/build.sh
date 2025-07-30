#!/bin/bash -e

SOURCE="$DS_WORK/components/mwifiex-external-module/"
# Kernel modules must install over existing kernel deploy to correctly provide
# module metadata (eg depmod, symvers, etc) for any external modules
INSTALL="$DS_WORK/overlays/kernel/"
KERNEL_SOURCE="$DS_WORK/kernel/linux/"
export KBUILD_OUTPUT="$DS_WORK/kernel/linux-kbuild/"

cd "$KERNEL_SOURCE"
make M="$SOURCE" modules -j"$(nproc)"
make M="$SOURCE" INSTALL_MOD_PATH="$INSTALL" modules_install

install -d "$DS_WORK/overlays/kernel/etc/modules-load.d/"
echo "moal" > "$DS_WORK/overlays/kernel/etc/modules-load.d/moal.conf"
