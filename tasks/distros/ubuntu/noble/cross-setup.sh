#!/bin/bash

# Ubuntu's amd64 archive and target ports archive are separate mirrors.
CROSS_MIRROR="${CONFIG_DS_CUSTOM_APT_URL:-http://us.archive.ubuntu.com/ubuntu}"
CROSS_SECURITY_MIRROR="http://security.ubuntu.com/ubuntu"
CROSS_PORTS_MIRROR="http://ports.ubuntu.com/ubuntu-ports"
CROSS_COMPONENTS="main universe multiverse restricted"
CROSS_KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"

write_cross_sources() {
	local root="$1"
	cat > "$root/etc/apt/sources.list" <<EOF
deb [arch=amd64] ${CROSS_MIRROR} ${DS_RELEASE} ${CROSS_COMPONENTS}
deb [arch=amd64] ${CROSS_MIRROR} ${DS_RELEASE}-updates ${CROSS_COMPONENTS}
deb [arch=amd64] ${CROSS_MIRROR} ${DS_RELEASE}-backports ${CROSS_COMPONENTS}
deb [arch=amd64] ${CROSS_SECURITY_MIRROR} ${DS_RELEASE}-security ${CROSS_COMPONENTS}
EOF
	cat > "$root/etc/apt/sources.list.d/ports.list" <<EOF
deb [arch=${DS_TARGET_ARCH}] ${CROSS_PORTS_MIRROR} ${DS_RELEASE} ${CROSS_COMPONENTS}
deb [arch=${DS_TARGET_ARCH}] ${CROSS_PORTS_MIRROR} ${DS_RELEASE}-updates ${CROSS_COMPONENTS}
deb [arch=${DS_TARGET_ARCH}] ${CROSS_PORTS_MIRROR} ${DS_RELEASE}-backports ${CROSS_COMPONENTS}
deb [arch=${DS_TARGET_ARCH}] ${CROSS_PORTS_MIRROR} ${DS_RELEASE}-security ${CROSS_COMPONENTS}
EOF
}
