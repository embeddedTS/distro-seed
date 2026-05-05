#!/bin/bash -e

ROOT_DST="/tmp/downgrade-wpa-hostapd"
LIBSSL_DEB="libssl1.1_1.1.1f-1ubuntu2_${DS_TARGET_ARCH}.deb"
WPA_DEB="wpasupplicant_2.9-1ubuntu4.6_${DS_TARGET_ARCH}.deb"
HOSTAPD_DEB="hostapd_2.9-1ubuntu4.6_${DS_TARGET_ARCH}.deb"

set +e
dpkg -l | grep wpasupplicant >/dev/null 2>&1
RES="${?}"
set -e
if [ "${RES}" -eq 0 ]; then
	apt-get remove -y wpasupplicant

	set +e
	dpkg -l | grep hostapd >/dev/null 2>&1
	RES="${?}"
	set -e
	if [ "${RES}" -eq 0 ]; then
		apt-get remove -y hostapd
	fi

	dpkg -i "${ROOT_DST}/${LIBSSL_DEB}"
	dpkg -i "${ROOT_DST}/${WPA_DEB}"
	dpkg -i "${ROOT_DST}/${HOSTAPD_DEB}"
	systemctl disable hostapd

	apt-mark hold libssl1.1
	apt-mark hold wpasupplicant
	apt-mark hold hostapd
fi

rm -r "${ROOT_DST}"
