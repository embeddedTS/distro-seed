#!/bin/bash -e

SOURCE="$DS_WORK/components/ts7680-utils/"
GITURL="https://github.com/embeddedTS/ts7680-utils.git"
GITVERSION="v3.0.0"

# Older distributions use libgpiod 1.x, we need to use an older release tag
# of utils for that.
if [ "${DS_DISTRO}" == "debian" ] && [ "${DS_RELEASE_NUM}" == "12" ]; then
	GITVERSION="v2.0.0"
fi

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
