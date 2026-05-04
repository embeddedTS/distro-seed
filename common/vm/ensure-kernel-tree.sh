#!/bin/bash -e

kernel_key="$(cat /work/kernel/linux-cache-key)"
kernel_dir="/vm-work/kernel"
kernel_key_file="${kernel_dir}/linux-cache-key"

export DS_KERNEL_CACHE_KEY="$kernel_key"
export DS_KERNEL_SOURCE="${kernel_dir}/linux"
export KBUILD_OUTPUT="${kernel_dir}/linux-kbuild"
export DS_KERNEL_DTBS="${kernel_dir}/linux-dtbs"

if [[ -f "$kernel_key_file" ]] && [[ "$(cat "$kernel_key_file")" = "$kernel_key" ]]; then
    return 0 2>/dev/null || exit 0
fi

rm -rf "$DS_KERNEL_SOURCE" "$KBUILD_OUTPUT" "$DS_KERNEL_DTBS"
install -d "$DS_KERNEL_SOURCE"
tar -C "$DS_KERNEL_SOURCE" -xf /work/kernel/linux-source.tar
printf '%s\n' "$kernel_key" > "$kernel_key_file"
