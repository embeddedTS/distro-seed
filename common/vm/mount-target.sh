#!/bin/bash -e

/src/common/vm/ensure-rootfs-bind.sh

ROOTFS="${DS_TARGET_ROOTFS:-/vm-work/rootfs}"

mountpoint -q "$ROOTFS/proc" || mount -t proc proc "$ROOTFS/proc"
mountpoint -q "$ROOTFS/sys" || mount -t sysfs sysfs "$ROOTFS/sys"
mountpoint -q "$ROOTFS/dev" || mount --bind /dev "$ROOTFS/dev"
mkdir -p "$ROOTFS/dev/pts"
mountpoint -q "$ROOTFS/dev/pts" || mount --bind /dev/pts "$ROOTFS/dev/pts"
