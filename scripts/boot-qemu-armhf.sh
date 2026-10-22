#!/usr/bin/env bash
# Usage: scripts/boot-qemu-armhf.sh [--graphics] [rootfs.ext4]

# shellcheck source-path=SCRIPTDIR
set -euo pipefail
qemu="qemu-system-arm"
machine=virt,highmem=off
cpu=cortex-a15
source "$(dirname "${BASH_SOURCE[0]}")/lib/boot-qemu.sh"
