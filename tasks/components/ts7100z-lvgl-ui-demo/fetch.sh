#!/bin/bash -e

GITURL="https://github.com/embeddedts/ts7100z-lvgl-ui-demo"
GITVERSION="v${DS_MANIFEST_VERSION}"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "${DS_TASK_WORK}"
