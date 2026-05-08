#!/bin/bash -e

OUTPUT="${DS_WORK}/output"
SPDX_PATH="${OUTPUT}/${DS_OUTPUT_BASENAME}.spdx.json"

install -d "${OUTPUT}"

debsbom generate \
	-r "${DS_TARGET_ROOTFS}" \
	--distro-arch "${DS_TARGET_ARCH}" \
	-t spdx \
	-o "${SPDX_PATH}"
chmod 644 "${SPDX_PATH}"
