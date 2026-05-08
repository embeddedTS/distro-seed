#!/bin/bash -e

ROOTFS="${DS_TARGET_ROOTFS:-${DS_WORK}/rootfs}"
OUTPUT="${DS_WORK}/output"

install -d "${OUTPUT}"


# Build final filename
FILENAME="${DS_OUTPUT_BASENAME}.tar"

# Create base tarball
(
cd "${ROOTFS}"
tar --xattrs --xattrs-include='*' --acls --selinux --numeric-owner --sparse -cpf "${OUTPUT}/${FILENAME}" .
)

(
cd "${OUTPUT}"

# Compress tarball
if [[ "$CONFIG_DS_OUTPUT_ROOTFS_TAR_NONE" == 'y' ]]; then
	true;
elif [[ "$CONFIG_DS_OUTPUT_ROOTFS_TAR_XZ" == 'y' ]]; then
	xz -2 -T0 "${FILENAME}"
	EXT=".xz"
elif [[ "$CONFIG_DS_OUTPUT_ROOTFS_TAR_BZIP2" == 'y' ]]; then
	bzip2 "${FILENAME}"
	EXT=".bz2"
else 
        echo "Invalid compression!"
        exit 1
fi

# Create md5sum of the tarball
md5sum "${FILENAME}${EXT}" > "${FILENAME}${EXT}.md5"

printf '%s\n' "${FILENAME}${EXT}" > ".rootfs-tar-link-target"
printf '%s\n' "${FILENAME}${EXT}.md5" > ".rootfs-tar-md5-link-target"
)
