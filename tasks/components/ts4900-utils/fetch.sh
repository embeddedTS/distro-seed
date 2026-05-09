#!/bin/bash -e

GITURL="https://github.com/embeddedTS/ts4900-utils.git"

common/host/fetch_git.sh "$GITURL" "v${DS_MANIFEST_VERSION}" "${DS_TASK_WORK}"
