#!/bin/bash -e

SOURCE="$DS_WORK/components/wilc3000-external/"
GITURL="https://github.com/embeddedTS/wilc3000-external-module.git"

install -d "$SOURCE"
common/host/fetch_git.sh "$GITURL" "$CONFIG_DS_MODULE_WILC3000_GIT_VERSION" "$SOURCE"
