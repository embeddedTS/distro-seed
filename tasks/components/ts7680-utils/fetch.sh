#!/bin/bash -e

SOURCE="$DS_WORK/components/ts7680-utils/"
GITURL="https://github.com/embeddedTS/ts7680-utils.git"
GITVERSION="v2.0.0"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
