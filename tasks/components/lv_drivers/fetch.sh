#!/bin/bash -e

GITURL="https://github.com/lvgl/lv_drivers.git"
GITVERSION="v${DS_MANIFEST_VERSION}"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "${DS_TASK_WORK}"
common/host/fetch_blob.sh "${CONFIG_DS_COMPONENT_LV_DRIVERS_LVDRVCONF}" "${DS_TASK_WORK}"
