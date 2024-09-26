#!/bin/bash -e

SOURCE="$DS_WORK/components/tssupervisorupdate/"
GITURL="https://github.com/embeddedTS/tssupervisorupdate.git"
GITVERSION="${CONFIG_DS_COMPONENT_TSSSUPERVISORUPDATE_GIT_VERSION:-v1.0.1}"

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
