#!/bin/bash -e

SOURCE="$DS_WORK/components/imx-firmware"
GITURL="https://github.com/nxp-imx/imx-firmware.git"

install -d "$SOURCE"
common/host/fetch_git.sh "$GITURL" "$CONFIG_DS_COMPONENT_IMX_FIRMWARE_GIT_VERSION" "$SOURCE"

install -d "$DS_OVERLAY/lib/firmware/nxp/"

if [ "${CONFIG_DS_COMPONENT_IMX_FIRMWARE_IW612_SD}" == "y" ]; then
    install -m 644 "${SOURCE}/nxp/FwImage_IW612_SD/sd_w61x_v1.bin.se" "$DS_OVERLAY/lib/firmware/nxp/"
    install -m 644 "${SOURCE}/nxp/FwImage_IW612_SD/sduart_nw61x_v1.bin.se" "$DS_OVERLAY/lib/firmware/nxp/"
    install -m 644 "${SOURCE}/nxp/FwImage_IW612_SD/uartspi_n61x_v1.bin.se" "$DS_OVERLAY/lib/firmware/nxp/"
    install -m 644 "${SOURCE}/nxp/FwImage_IW612_SD/uartuart_n61x_v1.bin.se" "$DS_OVERLAY/lib/firmware/nxp/"
fi

VERSION="$CONFIG_DS_COMPONENT_IMX_FIRMWARE_GIT_VERSION"
VERSION="$(printf '%s' "$VERSION" | sed -E 's/[^A-Za-z0-9.+~]+/+/g; s/[+][+]+/+/g; s/^[+]//; s/[+]$//')"
if [[ ! "$VERSION" =~ ^[0-9] ]]; then
	VERSION="0.0.1${VERSION:++$VERSION}"
fi
VERSION="${VERSION:-0.0.1}~distroseed1"

install -d "$DS_OVERLAY_PKG_DEBIAN"
cat > "$DS_OVERLAY_PKG_DEBIAN/control" <<EOF
Package: distro-seed-ds-component-imx-firmware
Version: $VERSION
Architecture: $DS_TARGET_ARCH
Maintainer: distro-seed <distro-seed@example.invalid>
Section: misc
Priority: optional
Description: distro-seed generated NXP i.MX firmware
 Generated from distro-seed task DS_COMPONENT_IMX_FIRMWARE.
EOF
