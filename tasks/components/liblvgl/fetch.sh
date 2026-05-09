#!/bin/bash -e

GITURL="https://github.com/lvgl/lvgl.git"
GITVERSION="v${DS_MANIFEST_VERSION}"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "${DS_TASK_WORK}"
common/host/fetch_blob.sh "${CONFIG_DS_COMPONENT_LIBLVGL_LVCONF}" "${DS_TASK_WORK}"
