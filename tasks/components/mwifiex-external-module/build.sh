#!/bin/bash -e

SOURCE="$DS_WORK/components/mwifiex-external-module/"
source /src/common/vm/get_kernel_work_tree.sh

PACKAGE_INSTALL="$DS_OVERLAY"
INSTALL="$(mktemp -d /tmp/ds-mwifiex-install.XXXXXX)"
KERNEL_SOURCE="$DS_KERNEL_SOURCE"
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

install -d "$package_module_dir" "$PACKAGE_INSTALL/etc/modules-load.d/"
cp -a "$module_dir/updates" "$package_module_dir/"
cp -a "$module_dir"/modules.* "$package_module_dir/"
echo "moal" > "$PACKAGE_INSTALL/etc/modules-load.d/moal.conf"
VERSION="$CONFIG_DS_MODULE_MWIFIEX_GIT_VERSION"
VERSION="$(printf '%s' "$VERSION" | sed -E 's/[^A-Za-z0-9.+~]+/+/g; s/[+][+]+/+/g; s/^[+]//; s/[+]$//')"
if [[ ! "$VERSION" =~ ^[0-9] ]]; then
	VERSION="0.0.1${VERSION:++$VERSION}"
fi
VERSION="${VERSION:-0.0.1}~distroseed1"

install -d "$DS_OVERLAY_PKG_DEBIAN"
cat > "$DS_OVERLAY_PKG_DEBIAN/control" <<EOF
Package: distro-seed-ds-module-mwifiex
Version: $VERSION
Architecture: $DS_TARGET_ARCH
Maintainer: distro-seed <distro-seed@example.invalid>
Section: kernel
Priority: optional
Description: distro-seed generated mwifiex kernel modules
 Generated from distro-seed task DS_MODULE_MWIFIEX.
EOF
