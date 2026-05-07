#!/bin/bash -e

kernel_dir="/vm-work/kernel"

export DS_KERNEL_SOURCE="${kernel_dir}/linux"
export KBUILD_OUTPUT="${kernel_dir}/linux-kbuild"
export DS_KERNEL_DTBS="${kernel_dir}/linux-dtbs"
export DS_KERNEL_INSTALL="${kernel_dir}/linux-install"

rm -rf "$DS_KERNEL_SOURCE" "$DS_KERNEL_DTBS"
install -d "$DS_KERNEL_SOURCE"
tar -C "$DS_KERNEL_SOURCE" -xf /work/kernel/linux-source.tar
