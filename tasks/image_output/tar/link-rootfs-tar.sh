#!/bin/bash -e

OUTPUT="${DS_WORK}/output"

cd "${OUTPUT}"

target=$(cat .rootfs-tar-link-target)
md5_target=$(cat .rootfs-tar-md5-link-target)
ext="${target#*.tar}"

rm -f "rootfs.tar${ext}" "rootfs.tar${ext}.md5"
ln -s "${target}" "rootfs.tar${ext}"
ln -s "${md5_target}" "rootfs.tar${ext}.md5"
rm -f .rootfs-tar-link-target .rootfs-tar-md5-link-target
