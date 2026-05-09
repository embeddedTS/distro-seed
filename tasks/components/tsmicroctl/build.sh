#!/bin/bash -e

SOURCE="$DS_STAGING"

cd "$SOURCE"

meson setup --cross-file "$MESON_CROSS" builddir
cd builddir
meson compile
DESTDIR="$DS_OVERLAY" meson install

install -d "$DS_OVERLAY/etc/systemd/system/"
install -m 644 "tsmicroctl.service" "$DS_OVERLAY/etc/systemd/system/"
