#!/bin/bash -e

PACKAGES="${DS_WORK}/packages"
ROOTFS="${DS_TARGET_ROOTFS:-${DS_WORK}/rootfs}"
TARGET_PACKAGE_DIR="${ROOTFS}/tmp/distro-seed-packages"

package_sort_key() {
    path="$1"
    name="$(basename "$path")"
    if [[ "$name" =~ ^([0-9]+)- ]]; then
        printf '%010d\t%s\n' "${BASH_REMATCH[1]}" "$path"
    else
        printf '9999999999\t%s\n' "$path"
    fi
}

shopt -s nullglob
packages=("$PACKAGES"/*.deb)
if [[ "${#packages[@]}" -eq 0 ]]; then
    exit 0
fi

/src/common/vm/mount-target.sh

QEMU_STATIC_PATH=$(which "${DS_QEMU_STATIC}")
install -d "${ROOTFS}/$(dirname "${QEMU_STATIC_PATH}")"
cp "${QEMU_STATIC_PATH}" "${ROOTFS}/${QEMU_STATIC_PATH}"

if [[ ! -e "${ROOTFS}/dev/zero" ]]; then
    mknod -m 666 "${ROOTFS}/dev/zero" c 1 5
fi
if [[ ! -e "${ROOTFS}/dev/null" ]]; then
    mknod -m 666 "${ROOTFS}/dev/null" c 1 3
fi

rm -rf "$TARGET_PACKAGE_DIR"
install -d "$TARGET_PACKAGE_DIR"

{
    for package in "${packages[@]}"; do
        package_sort_key "$package"
    done
} | sort -n -k1,1 | cut -f2- | while IFS= read -r package; do
    cp "$package" "$TARGET_PACKAGE_DIR/"
    chroot "$ROOTFS" dpkg -i --force-overwrite "/tmp/distro-seed-packages/$(basename "$package")"
done

rm -rf "$TARGET_PACKAGE_DIR"
