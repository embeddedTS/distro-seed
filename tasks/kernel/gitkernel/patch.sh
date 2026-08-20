#!/bin/bash -e

if [[ -z "$CONFIG_DS_KERNEL_PATCH_DIR" ]]; then
    exit 0
fi

patch_dir="$CONFIG_DS_KERNEL_PATCH_DIR"
if [[ "$patch_dir" != /* ]]; then
    patch_dir="${DS_HOST_ROOT_PATH}/${patch_dir}"
fi

if [[ ! -d "$patch_dir" ]]; then
    echo "Kernel patch directory not found: $patch_dir" >&2
    exit 1
fi

shopt -s nullglob
patches=("$patch_dir"/*.patch)
if (( ${#patches[@]} == 0 )); then
    echo "No kernel patches found in: $patch_dir"
    exit 0
fi

cd "${DS_TASK_WORK}/source"
for patch in "${patches[@]}"; do
    echo "Applying kernel patch: $patch"
    git apply --check --whitespace=nowarn "$patch"
    git apply --whitespace=nowarn "$patch"
done
