#!/bin/bash -e

install -d /etc/initramfs-tools
touch /etc/initramfs-tools/modules
read -r -a modules <<< "$CONFIG_DS_INITRAMFS_MODULES"
for module in "${modules[@]}"; do
    if ! grep -Fxq -- "$module" /etc/initramfs-tools/modules; then
        printf '%s\n' "$module" >> /etc/initramfs-tools/modules
    fi
done

update-initramfs -u -k all
