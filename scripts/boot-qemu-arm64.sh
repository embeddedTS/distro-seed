#!/usr/bin/env bash
# Usage: scripts/boot-qemu-arm64.sh [--graphics] [rootfs.ext4]

# shellcheck source-path=SCRIPTDIR
set -euo pipefail
qemu="qemu-system-aarch64"
machine=virt
cpu=cortex-a57
source "$(dirname "${BASH_SOURCE[0]}")/lib/boot-qemu.sh"
