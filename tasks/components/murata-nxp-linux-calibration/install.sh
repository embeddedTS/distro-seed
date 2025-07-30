#!/bin/bash -e

MODULE=""
CC=""

if [ "${CONFIG_DS_COMPONENT_MURATA_NXP_LINUX_CALIBRATION_2DL}" == "y" ]; then
	MODULE="2DL"
fi

if [ "${CONFIG_DS_COMPONENT_MURATA_NXP_LINUX_CALIBRATION_2DL_US}" == "y" ]; then
	CC="US"
elif [ "${CONFIG_DS_COMPONENT_MURATA_NXP_LINUX_CALIBRATION_2DL_EU}" == "y" ]; then
	CC="EU"
elif [ "${CONFIG_DS_COMPONENT_MURATA_NXP_LINUX_CALIBRATION_2DL_JP}" == "y" ]; then
	CC="JP"
elif [ "${CONFIG_DS_COMPONENT_MURATA_NXP_LINUX_CALIBRATION_2DL_CA}" == "y" ]; then
	CC="CA"
fi

/bin/bash /lib/firmware/nxp/murata/switch_regions.sh "$MODULE" "$CC"
