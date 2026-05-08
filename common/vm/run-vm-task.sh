#!/bin/bash

set -e

# Overlay contents are packaged with preserved modes, so keep default modes
# stable for files that tasks create without an explicit install/chmod mode.
umask 022

export DS_PYTHON_VENV="${DS_PYTHON_VENV:-/opt/distro-seed/venv}"
if [ -r /etc/profile.d/distro-seed-venv.sh ]; then
	source /etc/profile.d/distro-seed-venv.sh
elif [ -r "${DS_PYTHON_VENV}/bin/activate" ]; then
	source "${DS_PYTHON_VENV}/bin/activate"
fi

overlay_tmp="$(mktemp -d /tmp/ds-overlay.XXXXXX)"
debian_tmp="$(mktemp -d /tmp/ds-overlay-debian.XXXXXX)"
package_input="/work/package-inputs/$DS_PACKAGE_INPUT_NAME"

rm -rf "$package_input"

export DS_OVERLAY="$overlay_tmp"
export DS_OVERLAY_PKG_DEBIAN="$debian_tmp"

"$DS_TASK_CMD"

/src/common/vm/stage-package-input.sh "$package_input" "$overlay_tmp" "$debian_tmp"

rm -rf "$overlay_tmp"
rm -rf "$debian_tmp"
