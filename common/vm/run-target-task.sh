#!/bin/bash

set -e

/src/common/vm/mount-target.sh

rootfs="${DS_TARGET_ROOTFS:-/vm-work/rootfs}"
cp "$DS_TASK_CMD" "$rootfs/run_in_chroot"
export -p > "$rootfs/tmp/ds-env"
chroot "$rootfs" /bin/bash -lc 'source /tmp/ds-env; /run_in_chroot'
rm -f "$rootfs/run_in_chroot" "$rootfs/tmp/ds-env"
