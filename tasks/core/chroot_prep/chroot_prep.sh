#!/bin/bash -e

# This command runs from the VM environment to prep the chroot environment
# to run further commands.

ROOTFS="${DS_TARGET_ROOTFS:-${DS_WORK}/rootfs}"
QEMU_STATIC_PATH=$(which ${DS_QEMU_STATIC})
cp "${QEMU_STATIC_PATH}" "${ROOTFS}/${QEMU_STATIC_PATH}"

if [ ! -e "${ROOTFS}/dev/zero" ]; then
    mknod -m 666 "${ROOTFS}/dev/zero" c 1 5
fi
if [ ! -e "${ROOTFS}/dev/null" ]; then
    mknod -m 666 "${ROOTFS}/dev/null" c 1 3
fi

# Set up a temporary resolv.conf.
if [ -L "${ROOTFS}/etc/resolv.conf" ]; then
    cd "${ROOTFS}/etc/"
    install -d $(dirname $(readlink resolv.conf))
    echo "nameserver 1.1.1.1" > "${ROOTFS}/etc/resolv.conf"
fi
