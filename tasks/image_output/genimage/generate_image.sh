#!/bin/bash -e

GENIMAGE="$DS_WORK/components/host-genimage/genimage"
OUTPUT="$DS_WORK/output"

PLATFORM=$(basename "${CONFIG_DS_DEFCONFIG}")
PKGVARIANT="${PLATFORM%%_defconfig}"
PKGVARIANT="${PKGVARIANT##*_}"
PLATFORM="${PLATFORM%%_*}"
DATE=$(date +"%Y%m%d")

export GENIMAGE_CONFIG="$CONFIG_DS_GENIMAGE_PATH"
export GENIMAGE_INPUTPATH="$OUTPUT"
export GENIMAGE_OUTPUTPATH="$OUTPUT"
export GENIMAGE_TMPPATH="$DS_WORK/genimage-tmp/"

# Build final filename
FILENAME="${PLATFORM}-${DS_DISTRO}-${DS_RELEASE_NUM}-${DS_RELEASE}-${PKGVARIANT}-${DATE}.dd"

$GENIMAGE

# The genimage script needs to normalize on disk.img as the output. If that file
# does not exist, then throw an error
if [ ! -f "${OUTPUT}/disk.img" ]; then
	echo -e "\nDisk image file '${OUTPUT}/disk.img' does not exist (or is not a regular file). Ensure the genimage configuration file used outputs to the name 'disk.img'!\n"
	exit 1
fi


(
cd "${OUTPUT}"

# Move the disk.img file to the correct filename
mv disk.img "${FILENAME}"

# Compress tarball
if [[ "$CONFIG_DS_GENIMAGE_NONE" == 'y' ]]; then
	true;
elif [[ "$CONFIG_DS_GENIMAGE_XZ" == 'y' ]]; then
	xz -2 -T0 "${FILENAME}"
	EXT=".xz"
elif [[ "$CONFIG_DS_GENIMAGE_BZIP2" == 'y' ]]; then
	bzip2 "${FILENAME}"
	EXT=".bz2"
else
        echo "Invalid compression!"
        exit 1
fi

# Create md5sum of the tarball
md5sum "${FILENAME}${EXT}" > "${FILENAME}${EXT}.md5"

# Create simple symlink named rootfs
ln -sf "${FILENAME}${EXT}" "rootfs.dd${EXT}"
ln -sf "${FILENAME}${EXT}.md5" "rootfs.dd${EXT}.md5"
)
