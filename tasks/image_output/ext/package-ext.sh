#!/bin/bash -e

ROOTFS="$DS_WORK/rootfs/"
OUTPUT="$DS_WORK/output"
EXTFILE="${OUTPUT}/${CONFIG_DS_IMAGE_ROOTFS_EXT_LABEL}.ext${CONFIG_DS_IMAGE_ROOTFS_EXT_VER}"

install -d "$OUTPUT"

EXTOPTS="-d ${ROOTFS} -L ${CONFIG_DS_IMAGE_ROOTFS_EXT_LABEL} ${CONFIG_DS_IMAGE_ROOTFS_EXT_MKFS_OPTS}"

mkfs.ext"${CONFIG_DS_IMAGE_ROOTFS_EXT_VER}" ${EXTOPTS} "${EXTFILE}" "${CONFIG_DS_IMAGE_ROOTFS_EXT_SIZE}"

if [ "${CONFIG_DS_IMAGE_ROOTFS_EXT_XZ}" == "y" ]; then
    xz -2 "${EXTFILE}"
elif [ "${CONFIG_DS_IMAGE_ROOTFS_EXT_BZ2}" == "y" ]; then
    bzip2 "${EXTFILE}"
fi
