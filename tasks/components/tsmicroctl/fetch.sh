#!/bin/bash -e

SOURCE="$DS_WORK/components/tsmicroctl/"
GITURL="https://github.com/embeddedTS/tsmicroctl.git"
GITVERSION="v2.0.0"

# Older distributions use libgpiod 1.x, we need to use an older release tag
# of utils for that.
if [ "${DS_DISTRO}" == "debian" ] && [ "${DS_RELEASE_NUM}" == "12" ]; then
	GITVERSION="v1.0.3"
fi

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
