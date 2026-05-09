#!/bin/bash -e

SOURCE="$DS_STAGING"

PACKAGE_INSTALL="$DS_OVERLAY"
INSTALL="$(mktemp -d /tmp/ds-wilc3000-install.XXXXXX)"
KERNEL_SOURCE="$DS_STAGING_DS_KERNEL/source"
KERNEL_INSTALL="$DS_STAGING_DS_KERNEL/install"
export KBUILD_OUTPUT="$DS_STAGING_DS_KERNEL/build"
export CONFIG_WILC_SPI=m
cleanup() {
    rm -rf "$INSTALL"
}
trap cleanup EXIT

cp -a "$KERNEL_INSTALL/." "$INSTALL/"

cd "$KERNEL_SOURCE"
make M="$SOURCE" modules -j"$(nproc)"
make M="$SOURCE" INSTALL_MOD_PATH="$INSTALL" modules_install
kernel_release="$(make -s -C "$KERNEL_SOURCE" kernelrelease)"
module_dir="$INSTALL/lib/modules/$kernel_release"
package_module_dir="$PACKAGE_INSTALL/lib/modules/$kernel_release"

install -d "$package_module_dir"
cp -a "$module_dir/updates" "$package_module_dir/"
cp -a "$module_dir"/modules.* "$package_module_dir/"
VERSION="$CONFIG_DS_MODULE_WILC3000_GIT_VERSION"
VERSION="$(printf '%s' "$VERSION" | sed -E 's/[^A-Za-z0-9.+~]+/+/g; s/[+][+]+/+/g; s/^[+]//; s/[+]$//')"
if [[ ! "$VERSION" =~ ^[0-9] ]]; then
	VERSION="0.0.1${VERSION:++$VERSION}"
fi
VERSION="${VERSION:-0.0.1}~distroseed1"

install -d "$DS_OVERLAY_PKG_DEBIAN"
cat > "$DS_OVERLAY_PKG_DEBIAN/control" <<EOF
Package: distro-seed-ds-module-wilc3000
Version: $VERSION
Architecture: $DS_TARGET_ARCH
Maintainer: distro-seed <distro-seed@example.invalid>
Section: kernel
Priority: optional
Description: distro-seed generated WILC3000 kernel modules
 Generated from distro-seed task DS_MODULE_WILC3000.
EOF
