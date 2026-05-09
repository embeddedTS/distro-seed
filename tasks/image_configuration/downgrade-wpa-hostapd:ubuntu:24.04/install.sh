#!/bin/bash -e

ROOT_DST="/tmp/downgrade-wpa-hostapd"
LIBSSL_DEB="libssl1.1_1.1.1f-1ubuntu2_${DS_TARGET_ARCH}.deb"
WPA_DEB="wpasupplicant_2.9-1ubuntu4.6_${DS_TARGET_ARCH}.deb"
HOSTAPD_DEB="hostapd_2.9-1ubuntu4.6_${DS_TARGET_ARCH}.deb"

if dpkg-query -W -f='${db:Status-Abbrev}' wpasupplicant 2>/dev/null | grep -q '^ii '; then
	apt-get remove -y wpasupplicant

	if dpkg-query -W -f='${db:Status-Abbrev}' hostapd 2>/dev/null | grep -q '^ii '; then
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
