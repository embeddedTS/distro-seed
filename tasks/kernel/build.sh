#!/bin/bash

# Comment out if you don't want this script to exit immediately when
# any of its commands return an error:
set -e

source /src/common/vm/get_kernel_work_tree.sh

INSTALL_DTBS_PATH="$DS_KERNEL_DTBS"
SOURCE="$DS_KERNEL_SOURCE"
KERNEL_INSTALL="$DS_KERNEL_INSTALL"
PACKAGE_INSTALL="${DS_OVERLAY:-$DS_WORK/overlays/kernel/}"

[ -z "${ARCH_DIR}" ] && [ "$DS_TARGET_ARCH" = "armhf" ] && ARCH_DIR=arm
[ -z "${ARCH_DIR}" ] && [ "$DS_TARGET_ARCH" = "armel" ] && ARCH_DIR=arm
[ -z "${ARCH_DIR}" ] && [ "$DS_TARGET_ARCH" = "arm64" ] && ARCH_DIR=arm64
[ -z "${ARCH_DIR}" ] && echo "Unsupported arch for kernel build: ${DS_TARGET_ARCH}" && exit 1

rm -rf "$KBUILD_OUTPUT" "$KERNEL_INSTALL"
export KBUILD_OUTPUT
(
    cd "$SOURCE"
    # CROSS_COMPILE and ARCH are set from the cross chroot

    if [[ "$CONFIG_DS_KERNEL_INSTALL_IMAGE_FILESYSTEM" == 'y' ]]; then
        TARGETS="$TARGETS Image"
    fi

    if [[ "$CONFIG_DS_KERNEL_INSTALL_ZIMAGE_FILESYSTEM" == 'y' ]]; then
        TARGETS="$TARGETS zImage"
    fi

    if [[ "$CONFIG_DS_KERNEL_INSTALL_UIMAGE_FILESYSTEM" == 'y' ]]; then
        export LOADADDR="$CONFIG_DS_KERNEL_INSTALL_UIMAGE_LOADADDR"
        TARGETS="$TARGETS uImage"
    fi

    make "$CONFIG_DS_KERNEL_DEFCONFIG"
    make -j"$(nproc --all)" all $TARGETS

    install -d "${KERNEL_INSTALL}/boot"
    INSTALL_MOD_PATH="${KERNEL_INSTALL}" make modules_install

    # Copy out any pieces of the kernel build that we want in /boot
    if [[ "$CONFIG_DS_KERNEL_INSTALL_IMAGE_FILESYSTEM" == 'y' ]]; then
        cp "$KBUILD_OUTPUT/arch/${ARCH_DIR}/boot/Image" "${KERNEL_INSTALL}/boot/Image"
    fi

    if [[ "$CONFIG_DS_KERNEL_INSTALL_ZIMAGE_FILESYSTEM" == 'y' ]]; then
        cp "$KBUILD_OUTPUT/arch/${ARCH_DIR}/boot/zImage" "${KERNEL_INSTALL}/boot/zImage"
    fi

    if [[ "$CONFIG_DS_KERNEL_INSTALL_UIMAGE_FILESYSTEM" == 'y' ]]; then
        cp "$KBUILD_OUTPUT/arch/${ARCH_DIR}/boot/uImage" "${KERNEL_INSTALL}/boot/uImage"
    fi

    INSTALL_DTBS_PATH=$INSTALL_DTBS_PATH make dtbs_install
    for dtb in $CONFIG_DS_KERNEL_INSTALL_DEVICETREE_FILESYSTEM; do
        cp "$INSTALL_DTBS_PATH/${dtb}.dtb" "${KERNEL_INSTALL}/boot/"
    done
    for dtbo in $CONFIG_DS_KERNEL_INSTALL_DTBOS_FILESYSTEM; do
        cp "$INSTALL_DTBS_PATH/${dtbo}.dtbo" "${KERNEL_INSTALL}/boot/"
    done
)

install -d "$PACKAGE_INSTALL"
cp -a "$KERNEL_INSTALL/." "$PACKAGE_INSTALL/"

install -d "$DS_OVERLAY_PKG_DEBIAN"
kernel_release="$(make -s -C "$SOURCE" kernelrelease)"
cat > "$DS_OVERLAY_PKG_DEBIAN/control" <<EOF
Package: linux-image-distroseed
Version: $kernel_release
Architecture: $DS_TARGET_ARCH
Maintainer: distro-seed <distro-seed@example.invalid>
Section: kernel
Priority: optional
Description: distro-seed generated Linux kernel image
 Generated from distro-seed task DS_KERNEL_PROVIDER_GIT.
EOF
