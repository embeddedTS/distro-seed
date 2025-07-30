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
