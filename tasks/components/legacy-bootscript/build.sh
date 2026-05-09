#!/bin/bash -e

install -d "${DS_OVERLAY}/boot/"

echo "env set cmdline_append $CONFIG_DS_COMPONENT_LEGACY_BOOTSCRIPT_CMDLINE" > "${DS_TASK_WORK}/boot.source"

mkimage -A arm -T script -C none -n 'boot' \
        -d "${DS_TASK_WORK}/boot.source" "${DS_OVERLAY}/boot/boot.ub"

if [[ "$CONFIG_DS_COMPONENT_LEGACY_BOOTSCRIPT_INSTALL_SOURCE" == 'y' ]]; then
    install -m 644 "${DS_TASK_WORK}/boot.source" "${DS_OVERLAY}/boot/"
fi
