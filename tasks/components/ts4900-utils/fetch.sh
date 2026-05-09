#!/bin/bash -e

SOURCE="$DS_STAGING"
GITURL="https://github.com/embeddedTS/ts4900-utils.git"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "v${DS_MANIFEST_VERSION}" "$SOURCE"
