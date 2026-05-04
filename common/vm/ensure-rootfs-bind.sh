#!/bin/bash -e

ROOTFS_MOUNT="${DS_TARGET_ROOTFS:-/vm-work/rootfs}"

install -d "$ROOTFS_MOUNT"
