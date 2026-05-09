#!/bin/bash -e

PACKAGE_INSTALL="$DS_OVERLAY"
INSTALL="$(mktemp -d /tmp/ds-mwifiex-install.XXXXXX)"
export KBUILD_OUTPUT="${DS_TASK_WORK_DS_KERNEL}/build"
cleanup() {
    rm -rf "$INSTALL"
}
trap cleanup EXIT

cp -a "${DS_TASK_WORK_DS_KERNEL}/install/." "$INSTALL/"

cd "${DS_TASK_WORK_DS_KERNEL}/source"
make M="${DS_TASK_WORK}" modules -j"$(nproc)"
make M="${DS_TASK_WORK}" INSTALL_MOD_PATH="$INSTALL" modules_install

kernel_release="$(make -s -C "${DS_TASK_WORK_DS_KERNEL}/source" kernelrelease)"
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
