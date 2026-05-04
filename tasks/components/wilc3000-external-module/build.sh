#!/bin/bash -e

SOURCE="$DS_WORK/components/wilc3000-external/"
source /src/common/vm/ensure-kernel-tree.sh

PACKAGE_INSTALL="$DS_OVERLAY"
INSTALL="$(mktemp -d /tmp/ds-wilc3000-install.XXXXXX)"
KERNEL_SOURCE="$DS_KERNEL_SOURCE"
export CONFIG_WILC_SPI=m
cleanup() {
    rm -rf "$INSTALL"
}
trap cleanup EXIT

common/host/fetch_cache_obj.sh "linux-kernel-install-${DS_KERNEL_CACHE_KEY}" "$INSTALL"

cd "$KERNEL_SOURCE"
make M="$SOURCE" modules -j"$(nproc)"
make M="$SOURCE" INSTALL_MOD_PATH="$INSTALL" modules_install
kernel_release="$(make -s -C "$KERNEL_SOURCE" kernelrelease)"
module_dir="$INSTALL/lib/modules/$kernel_release"
package_module_dir="$PACKAGE_INSTALL/lib/modules/$kernel_release"

install -d "$package_module_dir"
cp -a "$module_dir/updates" "$package_module_dir/"
cp -a "$module_dir"/modules.* "$package_module_dir/"
install -d "$DS_OVERLAY_CONTROL"
printf '%s\n' "$kernel_release" > "$DS_OVERLAY_CONTROL/version"
