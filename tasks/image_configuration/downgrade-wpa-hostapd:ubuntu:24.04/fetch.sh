#!/bin/bash -e

ROOT_DST="${DS_OVERLAY}/tmp/downgrade-wpa-hostapd"

LIBSSL_DEB="libssl1.1_1.1.1f-1ubuntu2_${DS_TARGET_ARCH}.deb"
LIBSSL_SITE="http://ports.ubuntu.com/pool/main/o/openssl/${LIBSSL_DEB}"
[ "${DS_TARGET_ARCH}" = "arm64" ] && LIBSSL_SHA256="a697e5826bdbed1324f3cce1335ef162bf49eed433eb662c6d43e69ebc4807b2"
[ "${DS_TARGET_ARCH}" = "armhf" ] && LIBSSL_SHA256="fde1628edbebc3b4aba18f2568b703a4c2003e4903c4e01f899b489f4e426d3f"

WPA_DEB="wpasupplicant_2.9-1ubuntu4.6_${DS_TARGET_ARCH}.deb"
WPA_SITE="http://ports.ubuntu.com/pool/main/w/wpa/${WPA_DEB}"
[ "${DS_TARGET_ARCH}" = "arm64" ] && WPA_SHA256="acfb5532959c498798f54aba9086632c0d8e7d622a6440efe4d484538472e121"
[ "${DS_TARGET_ARCH}" = "armhf" ] && WPA_SHA256="82188b5404b63526b68f37b94755a1d62433c81b412b9d28573033ec9f999258"

HOSTAPD_DEB="hostapd_2.9-1ubuntu4.6_${DS_TARGET_ARCH}.deb"
HOSTAPD_SITE="http://ports.ubuntu.com/pool/universe/w/wpa/${HOSTAPD_DEB}"
[ "${DS_TARGET_ARCH}" = "arm64" ] && HOSTAPD_SHA256="cf1aade07ce26f44be403601d5c1ae8c4988f6c9d443d6f5862b938d900518ff"
[ "${DS_TARGET_ARCH}" = "armhf" ] && HOSTAPD_SHA256="8f8bf45387502b72636bc5a25900a978de3d5e8087dbe8a25f51870342e3bb18"

install -d "${ROOT_DST}"
common/host/fetch_blob.sh "${LIBSSL_SITE}" "${ROOT_DST}/${LIBSSL_DEB}" "${LIBSSL_SHA256}"
common/host/fetch_blob.sh "${WPA_SITE}" "${ROOT_DST}/${WPA_DEB}" "${WPA_SHA256}"
common/host/fetch_blob.sh "${HOSTAPD_SITE}" "${ROOT_DST}/${HOSTAPD_DEB}" "${HOSTAPD_SHA256}"
