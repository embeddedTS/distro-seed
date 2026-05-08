#!/bin/bash -e

OUTPUT="${DS_WORK}/output"

git_url_leaf() {
	url="${1%/}"
	leaf="${url##*/}"
	leaf="${leaf%.git}"
	leaf="$(printf '%s' "$leaf" | sed -E 's/[^A-Za-z0-9.+_-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
	printf '%s\n' "${leaf:-kernel}"
}

if [[ "${CONFIG_DS_KERNEL_PROVIDER_GIT:-n}" != "y" ]]; then
	exit 0
fi

if [[ ! -r "${DS_WORK}/kernel/linux/SBOM.spdx.json" ]]; then
	echo "Kernel source SBOM not found at ${DS_WORK}/kernel/linux/SBOM.spdx.json" >&2
	exit 0
fi

install -d "${OUTPUT}"
kernel_spdx_name="$(git_url_leaf "${CONFIG_DS_KERNEL_PROVIDER_GIT_URL}").spdx.json"
cp "${DS_WORK}/kernel/linux/SBOM.spdx.json" "${OUTPUT}/${kernel_spdx_name}"
chmod 644 "${OUTPUT}/${kernel_spdx_name}"
