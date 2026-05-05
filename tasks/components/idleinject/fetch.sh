#!/bin/bash -e

SOURCE="$DS_WORK/components/idleinject/"
GITURL="https://github.com/embeddedTS/idleinject.git"
GITVERSION="v${DS_MANIFEST_VERSION}"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
