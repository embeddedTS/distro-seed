#!/bin/bash -e

SOURCE="$DS_WORK/components/idleinject/"
GITURL="https://github.com/embeddedTS/idleinject.git"
GITVERSION="v1.1.0"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"