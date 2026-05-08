#!/bin/bash -e

QEMU_DIR="${DS_WORK}/qemu-host"
BUILD_DIR="${QEMU_DIR}/build"
ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso"
ISO_SHA256="0b813535dd76f2ea96eff908c65e8521512c92a0631fd41c95756ffd7d4896dc"
ISO="${QEMU_DIR}/debian-13.4.0-amd64-netinst.iso"
BASE_IMAGE="${QEMU_DIR}/base.qcow2"
KEY_FILE="${QEMU_DIR}/.vm-cache-key"
BUILD_VM_PATH="${DS_HOST_ROOT_PATH}/tasks/core/build_vm"
PACKAGE_FILE="${BUILD_VM_PATH}/packagelist-vm.txt"

if [[ "$(uname -m)" != "x86_64" ]]; then
	echo "The distro-seed VM requires an x86_64 host" >&2
	exit 1
fi

if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
	echo "KVM is required, but /dev/kvm is not available to this user" >&2
	exit 1
fi

for tool in qemu-system-x86_64 qemu-img xorriso cpio gzip sha256sum python3; do
	if ! command -v "$tool" >/dev/null 2>&1; then
		echo "$tool is required to build the distro-seed VM" >&2
		exit 1
	fi
done

valid_qcow2() {
	image="$1"
	[[ -r "$image" ]] && qemu-img info -f qcow2 "$image" >/dev/null 2>&1
}

install -d "$QEMU_DIR" "$DS_CACHE"
common/host/fetch_blob.sh "$ISO_URL" "$ISO" "$ISO_SHA256"

CACHE_KEY="$(
	{
		printf '%s\n' "Debian 13"
		sed -e 's/#.*$//' -e '/^$/d' "$PACKAGE_FILE"
	} | sha256sum | cut -f 1 -d ' '
)"
CACHED_BASE_IMAGE="${DS_CACHE}/vm-base-${CACHE_KEY}.qcow2"

use_cached_base() {
	echo "Using cached VM base image: $CACHED_BASE_IMAGE"
	rm -f "$BASE_IMAGE"
	ln -s "$CACHED_BASE_IMAGE" "$BASE_IMAGE"
	printf '%s\n' "$CACHE_KEY" > "$KEY_FILE"
}

OLD_CACHE_KEY=""
if [[ -r "$KEY_FILE" ]]; then
	OLD_CACHE_KEY="$(cat "$KEY_FILE")"
fi

if [[ -n "$OLD_CACHE_KEY" && "$OLD_CACHE_KEY" != "$CACHE_KEY" ]]; then
	echo "VM image cache key changed; removing old VM image"
	rm -f "$BASE_IMAGE" "${QEMU_DIR}/runtime.qcow2"
elif [[ -e "$BASE_IMAGE" ]] && ! valid_qcow2 "$BASE_IMAGE"; then
	echo "VM image is invalid; removing old VM image"
	rm -f "$BASE_IMAGE" "${QEMU_DIR}/runtime.qcow2"
fi

if [[ "$OLD_CACHE_KEY" == "$CACHE_KEY" ]] && valid_qcow2 "$BASE_IMAGE"; then
	if ! valid_qcow2 "$CACHED_BASE_IMAGE"; then
		rm -f "$CACHED_BASE_IMAGE"
		if [[ -L "$BASE_IMAGE" ]]; then
			cp --reflink=auto "$(readlink -f "$BASE_IMAGE")" "$CACHED_BASE_IMAGE"
		else
			mv "$BASE_IMAGE" "$CACHED_BASE_IMAGE"
		fi
	fi
	use_cached_base
	exit 0
fi

rm -f "${QEMU_DIR}/runtime.qcow2"
if valid_qcow2 "$CACHED_BASE_IMAGE"; then
	use_cached_base
	exit 0
fi

echo "Building VM base image: $CACHED_BASE_IMAGE"
rm -rf "$BUILD_DIR"
rm -f "$BASE_IMAGE" "$CACHED_BASE_IMAGE"
install -d "$BUILD_DIR/initrd-overlay"
QMP_SOCKET="${BUILD_DIR}/install-qmp.sock"
BUILD_BASE_IMAGE="${BUILD_DIR}/base.qcow2"

qemu-img create -f qcow2 "$BUILD_BASE_IMAGE" 32G
xorriso -osirrox on -indev "$ISO" -extract /install.amd/vmlinuz "$BUILD_DIR/vmlinuz" -extract /install.amd/initrd.gz "$BUILD_DIR/initrd.gz" >/dev/null 2>&1

PACKAGES="$(sed -e 's/#.*$//' -e '/^$/d' "$PACKAGE_FILE" | tr -s '[:space:]' ' ' | sed 's/^ //;s/ $//')"
cat > "$BUILD_DIR/preseed.cfg" <<EOF
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string distro-seed-vm
d-i netcfg/get_domain string local
d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string
d-i passwd/root-login boolean true
d-i passwd/make-user boolean false
d-i passwd/root-password password distro-seed
d-i passwd/root-password-again password distro-seed
d-i clock-setup/utc boolean true
d-i time/zone string UTC
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i apt-setup/non-free boolean true
d-i apt-setup/contrib boolean true
tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/include string ${PACKAGES}
d-i pkgsel/upgrade select none
popularity-contest popularity-contest/participate boolean false
d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string /dev/vda
d-i finish-install/reboot_in_progress note
d-i debian-installer/exit/poweroff boolean true
d-i preseed/late_command string cp -r /image-overlay/. /target/; in-target /tmp/ds-late-command.sh
EOF

(
	cd "$BUILD_DIR/initrd-overlay"
	cp ../preseed.cfg preseed.cfg
	cp -a "${BUILD_VM_PATH}/overlay" image-overlay
	find . | cpio -o -H newc --quiet | gzip -9 > ../initrd-overlay.gz
)

# Linux initramfs supports concatenated archives. Append a tiny archive with
# the preseed and distro-seed files to Debian's original installer initrd
# instead of unpacking/repacking it, which would require root/fakeroot for
# device nodes inside the installer image.
cat "$BUILD_DIR/initrd.gz" "$BUILD_DIR/initrd-overlay.gz" > "$BUILD_DIR/initrd-preseed.gz"

python3 common/host/run_with_idle_timeout.py \
	--idle-timeout 180 \
	--log "${QEMU_DIR}/install.log" \
	--qmp-socket "$QMP_SOCKET" \
	--quiet \
	-- \
	qemu-system-x86_64 \
	-enable-kvm \
	-machine q35,accel=kvm \
	-cpu host \
	-smp "$(nproc)" \
	-m 6144 \
	-display none \
	-no-reboot \
	-kernel "$BUILD_DIR/vmlinuz" \
	-initrd "$BUILD_DIR/initrd-preseed.gz" \
	-append "auto=true priority=critical preseed/file=/preseed.cfg console=ttyS0,115200n8" \
	-drive "if=virtio,file=${BUILD_BASE_IMAGE},format=qcow2" \
	-cdrom "$ISO" \
	-netdev user,id=net0 \
	-device virtio-net-pci,netdev=net0 \
	-no-shutdown \
	-qmp "unix:${QMP_SOCKET},server=on,wait=off" \
	-monitor none \
	-serial stdio

mv "$BUILD_BASE_IMAGE" "$CACHED_BASE_IMAGE"
ln -s "$CACHED_BASE_IMAGE" "$BASE_IMAGE"
printf '%s\n' "$CACHE_KEY" > "$KEY_FILE"
rm -rf "$BUILD_DIR" "${QEMU_DIR}/runtime.qcow2"
