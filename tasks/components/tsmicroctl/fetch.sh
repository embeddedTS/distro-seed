#!/bin/bash -e

SOURCE="$DS_WORK/components/tsmicroctl/"
GITURL="https://github.com/embeddedTS/tsmicroctl.git"
GITVERSION="v${DS_MANIFEST_VERSION}"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
