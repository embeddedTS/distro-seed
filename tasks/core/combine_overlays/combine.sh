#!/bin/bash -e

ROOTFS="$DS_WORK/rootfs/"
INSTALL="$DS_WORK/overlays/"

for dir in $INSTALL/*/
do
    rsync -aKHAX --numeric-ids "$dir" "$ROOTFS"/
done
