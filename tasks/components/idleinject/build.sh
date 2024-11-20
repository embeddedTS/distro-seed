#!/bin/bash -e

SOURCE="$DS_WORK/components/idleinject/"

cd "$SOURCE"

meson setup --cross-file "$MESON_CROSS" builddir
cd builddir
meson compile
DESTDIR="$DS_OVERLAY" meson install
