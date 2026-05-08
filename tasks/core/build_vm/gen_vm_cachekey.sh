#!/bin/bash -e

build_vm_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmpfile="$(mktemp)"

(
	cd "$build_vm_path"
	find . -type f -exec md5sum "{}" + | sort > "$tmpfile"
)

cache_key="$(md5sum "$tmpfile" | cut -f 1 -d ' ')"
rm "$tmpfile"
printf '%s\n' "$cache_key"
