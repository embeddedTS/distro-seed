#!/bin/bash -e

ROOTFS_STORE=/var/lib/distro-seed/rootfs
ROOTFS_MOUNT=/work/rootfs

install -d /var/lib/distro-seed "$ROOTFS_STORE" /work

if mountpoint -q "$ROOTFS_MOUNT"; then
	exit 0
fi

if [[ -e "$ROOTFS_MOUNT" ]] && [[ -n "$(find "$ROOTFS_MOUNT" -mindepth 1 -print -quit)" ]]; then
	echo "$ROOTFS_MOUNT exists but is not a VM-local bind mount" >&2
	exit 1
fi

install -d "$ROOTFS_MOUNT"
mount --bind "$ROOTFS_STORE" "$ROOTFS_MOUNT"
