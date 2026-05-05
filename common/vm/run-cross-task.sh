#!/bin/bash

set -e

# Overlay contents are packaged with preserved modes, so keep default modes
# stable for files that tasks create without an explicit install/chmod mode.
umask 022

/src/tasks/core/cross_ready/setup-cross.sh

CROSS_ROOT=/tmp/distro-seed-cross
for dir in cache dl work src vm-work; do
    mkdir -p "$CROSS_ROOT/$dir"
    mountpoint -q "$CROSS_ROOT/$dir" || mount --bind "/$dir" "$CROSS_ROOT/$dir"
done

overlay_tmp="/tmp/ds-overlay-$DS_PACKAGE_INPUT_NAME"
debian_tmp="/tmp/ds-overlay-debian-$DS_PACKAGE_INPUT_NAME"
package_input="/work/package-inputs/$DS_PACKAGE_INPUT_NAME"

rm -rf "$package_input"
rm -rf "$CROSS_ROOT/$overlay_tmp"
rm -rf "$CROSS_ROOT/$debian_tmp"
mkdir -p "$CROSS_ROOT/$overlay_tmp"
mkdir -p "$CROSS_ROOT/$debian_tmp"

export DS_OVERLAY="$overlay_tmp"
export DS_OVERLAY_PKG_DEBIAN="$debian_tmp"
export -p > "$CROSS_ROOT/tmp/ds-env"
cat >> "$CROSS_ROOT/tmp/ds-env" <<'EOF'
source /distro-seed-cross-env
EOF

chroot "$CROSS_ROOT" /bin/bash -lc 'source /tmp/ds-env; cd /src; "$DS_TASK_CMD"'

/src/common/vm/stage-package-input.sh \
    "$package_input" \
    "$CROSS_ROOT/$overlay_tmp" \
    "$CROSS_ROOT/$debian_tmp"

rm -rf "$CROSS_ROOT/$overlay_tmp"
rm -rf "$CROSS_ROOT/$debian_tmp"
