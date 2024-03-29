#!/bin/bash -e

ROOTFS="$DS_WORK/rootfs/"
OUTPUT="$DS_WORK/output"
TARFILE="${OUTPUT}/rootfs.tar"

install -d "$OUTPUT"

if [[ "$CONFIG_DS_IMAGE_ROOTFS_TAR_NONE" == 'y' ]]; then
        COMPRESSION=""
elif [[ "$CONFIG_DS_IMAGE_ROOTFS_TAR_XZ" == 'y' ]]; then
        COMPRESSION="J"
        export XZ_OPT="-T0" # use multiple threads
        TARFILE="${TARFILE}.xz"
elif [[ "$CONFIG_DS_IMAGE_ROOTFS_TAR_BZIP2" == 'y' ]]; then
        COMPRESSION="j"
        TARFILE="${TARFILE}.bz2"
else 
        echo "Invalid compression!"
        exit 1
fi

cd $ROOTFS
tar c${COMPRESSION}f "$TARFILE" .
