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

    # Workaround for:
    #     dpkg: error: parsing file '/var/lib/dpkg/status' near line 8060 package 'wpasupplicant':
    #     value for 'Conffiles' field has malformed line 'remove-on-upgrade /etc/dbus-1/system.d/wpa_supplicant.conf '
    sed -i '/remove-on-upgrade \/etc\/dbus-1\/system.d\/wpa_supplicant.conf/d' ${ROOTFS}/var/lib/dpkg/status
fi
