#!/bin/bash

# Comment out if you don't want this script to exit immediately when
# any of its commands return an error:
set -e

INSTALL_DTBS_PATH="$DS_WORK/kernel/linux-dtbs"
SOURCE="$DS_WORK/kernel/linux/"
KBUILD_OUTPUT="$DS_WORK/kernel/linux-kbuild/"
KERNEL_CACHE_KEY="$(cat $DS_WORK/kernel/linux-cache-key)"
INSTALL="$DS_WORK/overlays/kernel/"

BUILD_OBJECT_KEY="linux-kernel-build-${KERNEL_CACHE_KEY}"
INSTALL_OBJECT_KEY="linux-kernel-install-${KERNEL_CACHE_KEY}"

[ -z "${ARCH_DIR}" ] && [ "$DS_TARGET_ARCH" = "armhf" ] && ARCH_DIR=arm
[ -z "${ARCH_DIR}" ] && [ "$DS_TARGET_ARCH" = "armel" ] && ARCH_DIR=arm
[ -z "${ARCH_DIR}" ] && [ "$DS_TARGET_ARCH" = "arm64" ] && ARCH_DIR=arm64
[ -z "${ARCH_DIR}" ] && echo "Unsupported arch for kernel build: ${DS_TARGET_ARCH}" && exit 1

# The kernel caching is a little unusual since we have two differenet objects to cache.
# The installed kernel+modules make up one cached object, and the build objects make up
# the other. We still need the build object in the cache to support building other modules
# that may use the kernel source as a dependency.
if ! common/host/fetch_cache_obj.sh "$BUILD_OBJECT_KEY" "$KBUILD_OUTPUT"; then
    export KBUILD_OUTPUT INSTALL
    (
        set +e
        cd "$SOURCE"
        # CROSS_COMPILE and ARCH are set from the dockerfile

        if [[ "$CONFIG_DS_KERNEL_INSTALL_IMAGE_FILESYSTEM" == 'y' ]]; then
            TARGETS="$TARGETS Image"
        fi

        if [[ "$CONFIG_DS_KERNEL_INSTALL_ZIMAGE_FILESYSTEM" == 'y' ]]; then
            [ "${ARCH_DIR}" != "arm64" ] && TARGETS="$TARGETS zImage"
        fi

        if [[ "$CONFIG_DS_KERNEL_INSTALL_UIMAGE_FILESYSTEM" == 'y' ]]; then
            export LOADADDR="$CONFIG_DS_KERNEL_INSTALL_UIMAGE_LOADADDR"
            [ "${ARCH_DIR}" != "arm64" ] && TARGETS="$TARGETS uImage"
        fi

        make "$CONFIG_DS_KERNEL_DEFCONFIG"
        make -j"$(nproc --all)" all $TARGETS
    )
    common/host/store_cache_obj.sh "$BUILD_OBJECT_KEY" "$KBUILD_OUTPUT"
fi

if ! common/host/fetch_cache_obj.sh "$INSTALL_OBJECT_KEY" "$INSTALL"; then
    export KBUILD_OUTPUT INSTALL
    (
        set +e
        cd "$SOURCE"

        install -d "${INSTALL}/boot"
        INSTALL_MOD_PATH="${INSTALL}" make modules_install

        # Copy out any pieces of the kernel build that we want in /boot
        if [[ "$CONFIG_DS_KERNEL_INSTALL_IMAGE_FILESYSTEM" == 'y' ]]; then
            cp "$KBUILD_OUTPUT/arch/${ARCH_DIR}/boot/Image" "${INSTALL}/boot/Image"
        fi

        if [[ "$CONFIG_DS_KERNEL_INSTALL_ZIMAGE_FILESYSTEM" == 'y' ]]; then
            cp "$KBUILD_OUTPUT/arch/${ARCH_DIR}/boot/zImage" "${INSTALL}/boot/zImage"
        fi

        if [[ "$CONFIG_DS_KERNEL_INSTALL_UIMAGE_FILESYSTEM" == 'y' ]]; then
            cp "$KBUILD_OUTPUT/arch/${ARCH_DIR}/boot/uImage" "${INSTALL}/boot/uImage"
        fi

        INSTALL_DTBS_PATH=$INSTALL_DTBS_PATH make dtbs_install
        for dtb in $CONFIG_DS_KERNEL_INSTALL_DEVICETREE_FILESYSTEM; do
            cp "$INSTALL_DTBS_PATH/${dtb}.dtb" "${INSTALL}/boot/"
        done

    )
    common/host/store_cache_obj.sh "$INSTALL_OBJECT_KEY" "$INSTALL"
fi
