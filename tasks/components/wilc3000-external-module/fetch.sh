#!/bin/bash -e

SOURCE="$DS_WORK/components/wilc3000-external/"
GITURL="https://github.com/embeddedTS/wilc3000-external-module.git"
GITVERSION="linux4microchip-2021.10-1"

install -d "$SOURCE"
common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
