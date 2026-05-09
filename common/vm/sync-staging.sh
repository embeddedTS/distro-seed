#!/bin/bash

set -e

src_root="/work/staging-archives"
dst_root="/vm-work/staging"

mkdir -p "$dst_root"

if [[ ! -d "$src_root" ]]; then
	exit 0
fi

for archive in "$src_root"/*.tar; do
	[[ -f "$archive" ]] || continue
	name="${archive##*/}"
	name="${name%.tar}"
	dst="${dst_root}/${name}"

	if [[ -e "$dst" ]]; then
		continue
	fi

	install -d "$dst"
	tar --xattrs --xattrs-include='*' --acls --selinux --numeric-owner --sparse \
		-C "$dst" -xpf "$archive"
done
