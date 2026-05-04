#!/bin/bash -e

SOURCE="$DS_WORK/components/murata-firmware/"
GITURL="https://github.com/murata-wireless/nxp-linux-calibration.git"

install -d "$SOURCE"
common/host/fetch_git.sh "$GITURL" "$CONFIG_DS_COMPONENT_MURATA_NXP_LINUX_CALIBRATION_GIT_VERSION" "$SOURCE"

install -d "$DS_OVERLAY/lib/firmware/nxp/murata/"
install -d "$DS_OVERLAY/lib/firmware/nxp/murata/files"
if [[ -n "$CONFIG_DS_COMPONENT_MURATA_NXP_LINUX_CALIBRATION_GIT_VERSION" ]]; then
    install -d "$DS_OVERLAY_CONTROL"
    printf '%s\n' "$CONFIG_DS_COMPONENT_MURATA_NXP_LINUX_CALIBRATION_GIT_VERSION" > "$DS_OVERLAY_CONTROL/version"
fi

install -m 644 "${SOURCE}/LICENSE" "$DS_OVERLAY/lib/firmware/nxp/murata/LICENSE"
install -m 644 "${SOURCE}/murata/switch_regions.sh" "$DS_OVERLAY/lib/firmware/nxp/murata/"
install -m 644 "${SOURCE}/murata/files/bt_power_config_1.sh" "$DS_OVERLAY/lib/firmware/nxp/murata/files/"
install -m 644 "${SOURCE}/murata/files/wifi_mod_para_murata.conf" "$DS_OVERLAY/lib/firmware/nxp/murata/files/"

if [ "${CONFIG_DS_COMPONENT_MURATA_NXP_LINUX_CALIBRATION_2DL}" == "y" ]; then
    install -d "$DS_OVERLAY/lib/firmware/nxp/murata/files/2DL"
    install -m 644 "${SOURCE}/murata/files/2DL/"* "$DS_OVERLAY/lib/firmware/nxp/murata/files/2DL/"
fi
