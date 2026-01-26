#!/bin/bash -e

SOURCE="$DS_WORK/components/ts7180-utils/"
GITURL="https://github.com/embeddedTS/ts7180-utils.git"
GITVERSION="v1.1.0"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
