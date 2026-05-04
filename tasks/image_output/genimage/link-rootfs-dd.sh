#!/bin/bash -e

OUTPUT="${DS_WORK}/output"

cd "${OUTPUT}"

target=$(cat .rootfs-dd-link-target)
md5_target=$(cat .rootfs-dd-md5-link-target)
ext="${target#*.dd}"

rm -f "rootfs.dd${ext}" "rootfs.dd${ext}.md5"
ln -s "${target}" "rootfs.dd${ext}"
ln -s "${md5_target}" "rootfs.dd${ext}.md5"
rm -f .rootfs-dd-link-target .rootfs-dd-md5-link-target
