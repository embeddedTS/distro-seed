#!/bin/bash -e

SOURCE="$DS_STAGING"
GITURL="https://github.com/embeddedTS/wilc3000-external-module.git"

install -d "$SOURCE"
common/host/fetch_git.sh "$GITURL" "$CONFIG_DS_MODULE_WILC3000_GIT_VERSION" "$SOURCE"
