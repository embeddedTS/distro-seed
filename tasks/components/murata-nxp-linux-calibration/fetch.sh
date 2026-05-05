#!/bin/bash -e

SOURCE="$DS_WORK/components/murata-firmware/"
GITURL="https://github.com/murata-wireless/nxp-linux-calibration.git"

install -d "$SOURCE"
common/host/fetch_git.sh "$GITURL" "$CONFIG_DS_COMPONENT_MURATA_NXP_LINUX_CALIBRATION_GIT_VERSION" "$SOURCE"

install -d "$DS_OVERLAY/lib/firmware/nxp/murata/"
install -d "$DS_OVERLAY/lib/firmware/nxp/murata/files"

install -m 644 "${SOURCE}/LICENSE" "$DS_OVERLAY/lib/firmware/nxp/murata/LICENSE"
install -m 644 "${SOURCE}/murata/switch_regions.sh" "$DS_OVERLAY/lib/firmware/nxp/murata/"
install -m 644 "${SOURCE}/murata/files/bt_power_config_1.sh" "$DS_OVERLAY/lib/firmware/nxp/murata/files/"
install -m 644 "${SOURCE}/murata/files/wifi_mod_para_murata.conf" "$DS_OVERLAY/lib/firmware/nxp/murata/files/"

if [ "${CONFIG_DS_COMPONENT_MURATA_NXP_LINUX_CALIBRATION_2DL}" == "y" ]; then
    install -d "$DS_OVERLAY/lib/firmware/nxp/murata/files/2DL"
    install -m 644 "${SOURCE}/murata/files/2DL/"* "$DS_OVERLAY/lib/firmware/nxp/murata/files/2DL/"
fi

VERSION="$CONFIG_DS_COMPONENT_MURATA_NXP_LINUX_CALIBRATION_GIT_VERSION"
VERSION="$(printf '%s' "$VERSION" | sed -E 's/[^A-Za-z0-9.+~]+/+/g; s/[+][+]+/+/g; s/^[+]//; s/[+]$//')"
if [[ ! "$VERSION" =~ ^[0-9] ]]; then
	VERSION="0.0.1${VERSION:++$VERSION}"
fi
VERSION="${VERSION:-0.0.1}~distroseed1"

install -d "$DS_OVERLAY_PKG_DEBIAN"
cat > "$DS_OVERLAY_PKG_DEBIAN/control" <<EOF
Package: distro-seed-ds-component-murata-nxp-linux-calibration
Version: $VERSION
Architecture: $DS_TARGET_ARCH
Maintainer: distro-seed <distro-seed@example.invalid>
Section: misc
Priority: optional
Description: distro-seed generated Murata NXP calibration firmware
 Generated from distro-seed task DS_COMPONENT_MURATA_NXP_LINUX_CALIBRATION.
EOF
