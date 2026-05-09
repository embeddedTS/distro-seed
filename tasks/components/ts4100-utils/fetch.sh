#!/bin/bash -e

GITURL="https://github.com/embeddedTS/ts4100-utils.git"
GITVERSION="v${DS_MANIFEST_VERSION}"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "${DS_TASK_WORK}"
