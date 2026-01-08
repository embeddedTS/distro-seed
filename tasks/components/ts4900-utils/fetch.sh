#!/bin/bash -e

SOURCE="$DS_WORK/components/ts4900-utils/"
GITURL="https://github.com/embeddedTS/ts4900-utils.git"
GITVERSION="v3.0.0"

# Older distributions use libgpiod 1.x, we need to use an older release tag
# of utils for that.
if ( [ "${DS_DISTRO}" == "debian" ] && [ "${DS_RELEASE_NUM}" == "12" ] ) || \
   ( [ "${DS_DISTRO}" == "ubuntu" ] && [ "${DS_RELEASE_NUM}" == "24.04" ] ); then
	GITVERSION="v2.0.2"
fi

install -d "$SOURCE"

common/host/fetch_git.sh "$GITURL" "$GITVERSION" "$SOURCE"
