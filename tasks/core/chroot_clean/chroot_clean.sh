#!/bin/bash -e

# This command runs from the VM environment to clean up anything left from
# the prep command

ROOTFS="${DS_TARGET_ROOTFS:-${DS_WORK}/rootfs}"
QEMU_STATIC_PATH=$(which ${DS_QEMU_STATIC})
rm -f "${ROOTFS}/${QEMU_STATIC_PATH}"

for path in "${ROOTFS}/dev" "${ROOTFS}/sys" "${ROOTFS}/proc"; do
    if mountpoint -q "$path"; then
        umount -R "$path" || umount -l "$path"
    fi
done

# Clean up any directories that are normally tmpfs/devtmpfs
rm -rf "${ROOTFS}"/dev/*
rm -rf "${ROOTFS}"/tmp/*
rm -rf "${ROOTFS}"/run/*

# Remove leftover apt lists
rm -rf "${ROOTFS}"/var/lib/apt/lists/*
rm -rf "${ROOTFS}"/var/cache/apt/*.bin

# mmdebstrap writes --aptopt values into the target apt configuration,
# including the temporary proxy config.
rm -f "${ROOTFS}/etc/apt/apt.conf.d/99mmdebstrap"
