#!/bin/bash -e

ROOT_DST="${DS_OVERLAY}/tmp/downgrade-wpa-hostapd"

LIBSSL_DEB="libssl1.1_1.1.1w-0+deb11u1_${DS_TARGET_ARCH}.deb"
LIBSSL_SITE="http://ftp.us.debian.org/debian/pool/main/o/openssl/${LIBSSL_DEB}"
[ "${DS_TARGET_ARCH}" = "arm64" ] && LIBSSL_SHA256="fe7a7d313c87e46e62e614a07137e4a476a79fc9e5aab7b23e8235211280fee3"
[ "${DS_TARGET_ARCH}" = "armhf" ] && LIBSSL_SHA256="42130c140f972d938d4b4a5ab9638675e6d1223fcff3042bbcc1829e3646eb00"

WPA_DEB="wpasupplicant_2.9.0-21+deb11u2_${DS_TARGET_ARCH}.deb"
WPA_SITE="http://ftp.us.debian.org/debian/pool/main/w/wpa/${WPA_DEB}"
[ "${DS_TARGET_ARCH}" = "arm64" ] && WPA_SHA256="834bad32fced528e9e8812138ae7d0d92ad7e6a92bcb60a913bebc713ad3e0b4"
[ "${DS_TARGET_ARCH}" = "armhf" ] && WPA_SHA256="dce8b75e6b4d6e8a59c98b2172d553de332026bc2f8705b63e12a1e980150a5b"

HOSTAPD_DEB="hostapd_2.9.0-21+deb11u2_${DS_TARGET_ARCH}.deb"
HOSTAPD_SITE="http://ftp.us.debian.org/debian/pool/main/w/wpa/${HOSTAPD_DEB}"
[ "${DS_TARGET_ARCH}" = "arm64" ] && HOSTAPD_SHA256="61a8c7dd81cff75298d7b0be6f5cb780f50ab31c03f80175288b41a7a2e74a4a"
[ "${DS_TARGET_ARCH}" = "armhf" ] && HOSTAPD_SHA256="67e82fc8753f7b6379bbeaad529170ec03ec3bba414c807a67512229a7cacdae"

install -d "${ROOT_DST}"
common/host/fetch_blob.sh "${LIBSSL_SITE}" "${ROOT_DST}/${LIBSSL_DEB}" "${LIBSSL_SHA256}"
common/host/fetch_blob.sh "${WPA_SITE}" "${ROOT_DST}/${WPA_DEB}" "${WPA_SHA256}"
common/host/fetch_blob.sh "${HOSTAPD_SITE}" "${ROOT_DST}/${HOSTAPD_DEB}" "${HOSTAPD_SHA256}"
