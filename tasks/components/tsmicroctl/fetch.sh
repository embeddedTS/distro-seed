#!/bin/bash -e

SOURCE="$DS_WORK/components/tsmicroctl/"
GITURL="https://github.com/embeddedTS/tsmicroctl.git"
GITVERSION="v1.0.1"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
