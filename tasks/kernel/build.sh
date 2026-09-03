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

    if [[ -n "$CONFIG_DS_KERNEL_DEFCONFIG_FILE" ]]; then
        kernel_defconfig_file="$CONFIG_DS_KERNEL_DEFCONFIG_FILE"
        if [[ "$kernel_defconfig_file" != /* ]]; then
            kernel_defconfig_file="${DS_HOST_ROOT_PATH}/${kernel_defconfig_file}"
        fi

        if [[ ! -f "$kernel_defconfig_file" ]]; then
            echo "Kernel defconfig file not found: $kernel_defconfig_file" >&2
            exit 1
        fi

        cp "$kernel_defconfig_file" "$KBUILD_OUTPUT/.config"
    else
        make "$CONFIG_DS_KERNEL_DEFCONFIG"
    fi

    if [[ -n "$CONFIG_DS_KERNEL_CONFIG_FRAGMENT_FILES" ]]; then
        read -r -a kernel_config_fragments <<< "$CONFIG_DS_KERNEL_CONFIG_FRAGMENT_FILES"
        for index in "${!kernel_config_fragments[@]}"; do
            fragment="${kernel_config_fragments[$index]}"
            if [[ "$fragment" != /* ]]; then
                fragment="${DS_HOST_ROOT_PATH}/${fragment}"
            fi

            if [[ ! -f "$fragment" ]]; then
                echo "Kernel configuration fragment not found: $fragment" >&2
                exit 1
            fi

            kernel_config_fragments[$index]="$fragment"
        done

        scripts/kconfig/merge_config.sh -m -O "$KBUILD_OUTPUT" \
            "$KBUILD_OUTPUT/.config" "${kernel_config_fragments[@]}"
    fi

    if [[ -n "$CONFIG_DS_KERNEL_DEFCONFIG_FILE" || -n "$CONFIG_DS_KERNEL_CONFIG_FRAGMENT_FILES" ]]; then
        make olddefconfig
    fi

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
