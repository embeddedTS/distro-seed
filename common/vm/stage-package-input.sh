#!/bin/bash

set -euo pipefail

package_input="$1"
overlay_tmp="$2"
debian_tmp="$3"

if [[ -z "$(find "$overlay_tmp" -mindepth 1 -print -quit)" ]]; then
    exit 0
fi

install -d "$package_input"
{
    printf 'DS_MANIFEST_VERSION=%q\n' "$DS_MANIFEST_VERSION"
    printf 'DS_PKG_VERSION=%q\n' "$DS_PKG_VERSION"
} > "$package_input/metadata.env"

tar --xattrs --xattrs-include='*' --acls --selinux --numeric-owner --sparse \
    -C "$overlay_tmp" -cpf "$package_input/data.tar" .

if [[ -n "$(find "$debian_tmp" -mindepth 1 -print -quit)" ]]; then
    tar --xattrs --xattrs-include='*' --acls --selinux --numeric-owner --sparse \
        -C "$debian_tmp" -cpf "$package_input/debian.tar" .
fi
