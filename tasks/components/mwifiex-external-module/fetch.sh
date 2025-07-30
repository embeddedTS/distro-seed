#!/bin/bash -e

SOURCE="$DS_WORK/components/mwifiex-external-module/"
GITURL="https://github.com/nxp-imx/mwifiex.git"

install -d "$SOURCE"
common/host/fetch_git.sh "$GITURL" "$CONFIG_DS_MODULE_MWIFIEX_GIT_VERSION" "$SOURCE"
