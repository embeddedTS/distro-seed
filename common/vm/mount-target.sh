#!/bin/bash -e

mountpoint -q /work/rootfs/proc || mount -t proc proc /work/rootfs/proc
mountpoint -q /work/rootfs/sys || mount -t sysfs sysfs /work/rootfs/sys
mountpoint -q /work/rootfs/dev || mount --bind /dev /work/rootfs/dev
mkdir -p /work/rootfs/dev/pts
mountpoint -q /work/rootfs/dev/pts || mount --bind /dev/pts /work/rootfs/dev/pts
