#!/bin/bash -e

SOURCE="$DS_STAGING"
GITURL="https://github.com/embeddedts/ts7100z-lvgl-ui-demo"
GITVERSION="v${DS_MANIFEST_VERSION}"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
