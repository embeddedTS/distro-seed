#!/bin/bash -e

SOURCE="$DS_WORK/components/tssupervisorupdate/"
GITURL="https://github.com/embeddedTS/tssupervisorupdate.git"
GITVERSION="v1.1.4"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
