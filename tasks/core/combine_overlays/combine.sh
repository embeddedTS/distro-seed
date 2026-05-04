#!/bin/bash -e

ROOTFS="$DS_WORK/rootfs/"
INSTALL="$DS_WORK/overlays/"

shopt -s nullglob
for dir in $INSTALL/*/
do
    if [[ -f "$dir/overlay.tar" ]]; then
        tar --xattrs --acls --numeric-owner -C "$ROOTFS" -xf "$dir/overlay.tar"
    else
        rsync -aKHAX --numeric-ids "$dir" "$ROOTFS"/
    fi
done
