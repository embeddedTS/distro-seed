#!/bin/bash -e

GITURL="https://github.com/embeddedTS/wilc3000-external-module.git"

common/host/fetch_git.sh "$GITURL" "$CONFIG_DS_MODULE_WILC3000_GIT_VERSION" "${DS_TASK_WORK}"
