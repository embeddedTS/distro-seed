#!/bin/bash -e

SOURCE="$DS_STAGING"
GITURL="https://github.com/embeddedTS/ts7400v2-utils-linux4.x.git"
GITVERSION="v${DS_MANIFEST_VERSION}"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
