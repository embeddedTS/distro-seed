#!/bin/bash -e

SOURCE="$DS_WORK/components/ts7670-utils/"
GITURL="https://github.com/embeddedTS/ts7670-utils-linux4.x.git"
GITVERSION="v2.0.0"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
