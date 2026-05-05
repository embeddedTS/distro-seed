#!/bin/bash -e

SOURCE="$DS_WORK/components/linux-firmware/"
GITURL="https://kernel.googlesource.com/pub/scm/linux/kernel/git/firmware/linux-firmware.git"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$CONFIG_DS_COMPONENT_LINUX_FIRMWARE_GIT_VERSION" "$SOURCE"

install -d "$DS_OVERLAY/lib/firmware/"

if [ "$CONFIG_DS_COMPONENT_LINUX_FIRMWARE_QCA9377" = "y" ]; then
        # Bluetooth
        install -d "$DS_OVERLAY/lib/firmware/qca"
        install -m 644 "${SOURCE}/qca/rampatch_00230302.bin" "$DS_OVERLAY/lib/firmware/qca/"
        install -m 644 "${SOURCE}/qca/nvm_00230302.bin" "$DS_OVERLAY/lib/firmware/qca/"
        # WIFI
        install -d "$DS_OVERLAY/lib/firmware/ath10k/QCA9377/hw1.0"
        install -m 644 "${SOURCE}/ath10k/QCA9377/hw1.0/board-2.bin" "$DS_OVERLAY/lib/firmware/ath10k/QCA9377/hw1.0/board-2.bin"
        install -m 644 "${SOURCE}/ath10k/QCA9377/hw1.0/board.bin" "$DS_OVERLAY/lib/firmware/ath10k/QCA9377/hw1.0/board.bin"
        install -m 644 "${SOURCE}/ath10k/QCA9377/hw1.0/firmware-5.bin" "$DS_OVERLAY/lib/firmware/ath10k/QCA9377/hw1.0/firmware-5.bin"
        install -m 644 "${SOURCE}/ath10k/QCA9377/hw1.0/firmware-6.bin" "$DS_OVERLAY/lib/firmware/ath10k/QCA9377/hw1.0/firmware-6.bin"
        install -m 644 "${SOURCE}/ath10k/QCA9377/hw1.0/firmware-sdio-5.bin" "$DS_OVERLAY/lib/firmware/ath10k/QCA9377/hw1.0/firmware-sdio-5.bin"
fi

VERSION="$CONFIG_DS_COMPONENT_LINUX_FIRMWARE_GIT_VERSION"
VERSION="$(printf '%s' "$VERSION" | sed -E 's/[^A-Za-z0-9.+~]+/+/g; s/[+][+]+/+/g; s/^[+]//; s/[+]$//')"
if [[ ! "$VERSION" =~ ^[0-9] ]]; then
	VERSION="0.0.1${VERSION:++$VERSION}"
fi
VERSION="${VERSION:-0.0.1}~distroseed1"

install -d "$DS_OVERLAY_PKG_DEBIAN"
cat > "$DS_OVERLAY_PKG_DEBIAN/control" <<EOF
Package: distro-seed-ds-component-linux-firmware
Version: $VERSION
Architecture: $DS_TARGET_ARCH
Maintainer: distro-seed <distro-seed@example.invalid>
Section: misc
Priority: optional
Description: distro-seed generated linux-firmware files
 Generated from distro-seed task DS_COMPONENT_LINUX_FIRMWARE.
EOF
