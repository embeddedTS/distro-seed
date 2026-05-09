#!/bin/bash -e

GITURL="https://github.com/embeddedTS/idleinject.git"
GITVERSION="v${DS_MANIFEST_VERSION}"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "${DS_TASK_WORK}"
