#!/bin/bash -e

GITURL="https://github.com/embeddedTS/ts7670-utils-linux4.x.git"
GITVERSION="v${DS_MANIFEST_VERSION}"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "${DS_TASK_WORK}"
