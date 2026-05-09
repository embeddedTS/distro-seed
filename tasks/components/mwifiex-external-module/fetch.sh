#!/bin/bash -e

GITURL="https://github.com/nxp-imx/mwifiex.git"

common/host/fetch_git.sh "$GITURL" "$CONFIG_DS_MODULE_MWIFIEX_GIT_VERSION" "${DS_TASK_WORK}"
