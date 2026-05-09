#!/bin/bash -e

cd "${DS_TASK_WORK}"

meson setup --cross-file "$MESON_CROSS" builddir
cd builddir
meson compile
DESTDIR="$DS_OVERLAY" meson install
