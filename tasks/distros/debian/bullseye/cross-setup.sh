#!/bin/bash

CROSS_MIRROR="${CONFIG_DS_CUSTOM_APT_URL:-http://deb.debian.org/debian}"
CROSS_COMPONENTS="main contrib non-free"
CROSS_KEYRING="/usr/share/keyrings/debian-archive-keyring.gpg"

write_cross_sources() {
	local root="$1"
	cat > "$root/etc/apt/sources.list" <<EOF
deb [arch=amd64] ${CROSS_MIRROR} ${DS_RELEASE} ${CROSS_COMPONENTS}
deb [arch=${DS_TARGET_ARCH}] ${CROSS_MIRROR} ${DS_RELEASE} main
EOF
}
