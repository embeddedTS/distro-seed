#!/bin/bash

# Comment out if you don't want this script to exit immediately when
# any of its commands return an error:
set -e

PACKAGE_INSTALL="${DS_OVERLAY:-$DS_WORK/overlays/kernel/}"

[ -z "${ARCH_DIR}" ] && [ "$DS_TARGET_ARCH" = "armhf" ] && ARCH_DIR=arm
[ -z "${ARCH_DIR}" ] && [ "$DS_TARGET_ARCH" = "armel" ] && ARCH_DIR=arm
[ -z "${ARCH_DIR}" ] && [ "$DS_TARGET_ARCH" = "arm64" ] && ARCH_DIR=arm64
[ -z "${ARCH_DIR}" ] && echo "Unsupported arch for kernel build: ${DS_TARGET_ARCH}" && exit 1

rm -rf "${DS_TASK_WORK}/build" "${DS_TASK_WORK}/dtbs" "${DS_TASK_WORK}/install"
install -d "${DS_TASK_WORK}/build" "${DS_TASK_WORK}/dtbs" "${DS_TASK_WORK}/install"
export KBUILD_OUTPUT="${DS_TASK_WORK}/build"
(
    cd "${DS_TASK_WORK}/source"
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

    install -d "${DS_TASK_WORK}/install/boot"
    INSTALL_MOD_PATH="${DS_TASK_WORK}/install" make modules_install

    # Copy out any pieces of the kernel build that we want in /boot
    if [[ "$CONFIG_DS_KERNEL_INSTALL_IMAGE_FILESYSTEM" == 'y' ]]; then
        cp "$KBUILD_OUTPUT/arch/${ARCH_DIR}/boot/Image" "${DS_TASK_WORK}/install/boot/Image"
    fi

    if [[ "$CONFIG_DS_KERNEL_INSTALL_ZIMAGE_FILESYSTEM" == 'y' ]]; then
        cp "$KBUILD_OUTPUT/arch/${ARCH_DIR}/boot/zImage" "${DS_TASK_WORK}/install/boot/zImage"
    fi

    if [[ "$CONFIG_DS_KERNEL_INSTALL_UIMAGE_FILESYSTEM" == 'y' ]]; then
        cp "$KBUILD_OUTPUT/arch/${ARCH_DIR}/boot/uImage" "${DS_TASK_WORK}/install/boot/uImage"
    fi

    INSTALL_DTBS_PATH="${DS_TASK_WORK}/dtbs" make dtbs_install
    for dtb in $CONFIG_DS_KERNEL_INSTALL_DEVICETREE_FILESYSTEM; do
        cp "${DS_TASK_WORK}/dtbs/${dtb}.dtb" "${DS_TASK_WORK}/install/boot/"
    done
    for dtbo in $CONFIG_DS_KERNEL_INSTALL_DTBOS_FILESYSTEM; do
        cp "${DS_TASK_WORK}/dtbs/${dtbo}.dtbo" "${DS_TASK_WORK}/install/boot/"
    done
)

install -d "$PACKAGE_INSTALL"
cp -a "${DS_TASK_WORK}/install/." "$PACKAGE_INSTALL/"

install -d "$DS_OVERLAY_PKG_DEBIAN"
kernel_release="$(make -s -C "${DS_TASK_WORK}/source" kernelrelease)"
kernel_source_name="${CONFIG_DS_KERNEL_PROVIDER_GIT_URL:-linux-distroseed}"
kernel_source_name="${kernel_source_name%/}"
kernel_source_name="${kernel_source_name##*/}"
kernel_source_name="${kernel_source_name%.git}"
kernel_source_name="$(printf '%s' "$kernel_source_name" \
    | tr '[:upper:]_' '[:lower:]-' \
    | sed -E 's/[^a-z0-9.+-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
kernel_source_name="${kernel_source_name:-linux-distroseed}"
cat > "$DS_OVERLAY_PKG_DEBIAN/control" <<EOF
Package: linux-image-distroseed
Source: $kernel_source_name
Version: $kernel_release
Architecture: $DS_TARGET_ARCH
Maintainer: distro-seed <distro-seed@example.invalid>
Section: kernel
Priority: optional
Homepage: ${CONFIG_DS_KERNEL_PROVIDER_GIT_URL}
Description: distro-seed generated Linux kernel image
 Generated from distro-seed task DS_KERNEL_PROVIDER_GIT.
EOF
