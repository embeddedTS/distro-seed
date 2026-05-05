#!/bin/bash -e

SOURCE="$DS_WORK/components/ts7180-utils/"
GITURL="https://github.com/embeddedTS/ts7180-utils.git"
GITVERSION="v${DS_MANIFEST_VERSION}"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
