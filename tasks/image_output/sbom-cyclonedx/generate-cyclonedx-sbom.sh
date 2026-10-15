#!/bin/bash -e

OUTPUT="${DS_WORK}/output"
CYCLONEDX_PATH="${OUTPUT}/${DS_OUTPUT_BASENAME}.cdx.json"

install -d "${OUTPUT}"

debsbom generate \
	-r "${DS_TARGET_ROOTFS}" \
	--distro-arch "${DS_TARGET_ARCH}" \
	-t cdx \
	-o "${CYCLONEDX_PATH}"
chmod 644 "${CYCLONEDX_PATH}"
