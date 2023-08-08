#!/bin/bash -e

SOURCE="$DS_WORK/components/ts4900-utils/"
GITURL="https://github.com/embeddedTS/ts4900-utils.git"
GITVERSION="v1.0.3"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
