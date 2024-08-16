#!/bin/bash -e

ROOTFS="$DS_WORK/rootfs"

if [ "$DS_DISTRO" == "ubuntu" ] && [ "$DS_RELEASE" == "noble" ]; then
    # Workaround for usrmerge breaking
    cp -a "${ROOTFS}/sbin/." "${ROOTFS}/usr/sbin/"
    cp -a "${ROOTFS}/bin/." "${ROOTFS}/usr/bin/"
    cp -a "${ROOTFS}/lib/." "${ROOTFS}/usr/lib/"

    rm -rf "${ROOTFS}/sbin" "${ROOTFS}/bin" "${ROOTFS}/lib"

    ln -sfn "usr/sbin" "${ROOTFS}/sbin"
    ln -sfn "usr/bin" "${ROOTFS}/bin"
    ln -sfn "usr/lib" "${ROOTFS}/lib"
fi
