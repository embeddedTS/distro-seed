#!/bin/sh
set -eu

export XDG_RUNTIME_DIR=/run/weston
export WAYLAND_DISPLAY=wayland-0

rm -rf "${XDG_RUNTIME_DIR}"
install -d -m 0700 "${XDG_RUNTIME_DIR}"

weston --backend=drm-backend.so \
    --config=/etc/xdg/weston/weston.ini \
    --socket="$WAYLAND_DISPLAY" \
    --continue-without-input
