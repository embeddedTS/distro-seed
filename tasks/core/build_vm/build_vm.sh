#!/bin/bash -e

QEMU_DIR="${DS_WORK}/qemu-host"
BUILD_DIR="${QEMU_DIR}/build"
ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso"
ISO_SHA256="0b813535dd76f2ea96eff908c65e8521512c92a0631fd41c95756ffd7d4896dc"
ISO="${QEMU_DIR}/debian-13.4.0-amd64-netinst.iso"
BASE_IMAGE="${QEMU_DIR}/base.qcow2"
KEY_FILE="${QEMU_DIR}/.vm-cache-key"
PACKAGE_FILE="${DS_HOST_ROOT_PATH}/packagelist-vm.txt"

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

install -d "$QEMU_DIR"
common/host/fetch_blob.sh "$ISO_URL" "$ISO" "$ISO_SHA256"

CACHE_KEY="$(
	{
		printf '%s\n' "Debian 13"
		sed -e 's/#.*$//' -e '/^$/d' "$PACKAGE_FILE"
	} | sha256sum | cut -f 1 -d ' '
)"

if [[ -r "$KEY_FILE" && -r "$BASE_IMAGE" && "$(cat "$KEY_FILE")" == "$CACHE_KEY" ]]; then
	exit 0
fi

rm -f "${QEMU_DIR}/runtime.qcow2"
if common/host/fetch_cache_obj.sh "$CACHE_KEY" "$QEMU_DIR"; then
	if [[ -r "$KEY_FILE" && -r "$BASE_IMAGE" && "$(cat "$KEY_FILE")" == "$CACHE_KEY" ]]; then
		exit 0
	fi
fi

rm -rf "$BUILD_DIR" "$BASE_IMAGE"
install -d "$BUILD_DIR/initrd-overlay"
QMP_SOCKET="${BUILD_DIR}/install-qmp.sock"

qemu-img create -f qcow2 "$BASE_IMAGE" 32G
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
d-i preseed/late_command string mkdir -p /target/usr/local/sbin /target/tmp; cp /ds-serial-agent /target/usr/local/sbin/ds-serial-agent; chmod 755 /target/usr/local/sbin/ds-serial-agent; cp /ds-late-command.sh /target/tmp/ds-late-command.sh; chmod 755 /target/tmp/ds-late-command.sh; in-target /tmp/ds-late-command.sh
EOF

cat > "$BUILD_DIR/ds-late-command.sh" <<'EOF'
#!/bin/bash -e

set_acng_option() {
	key="$1"
	value="$2"
	file=/etc/apt-cacher-ng/acng.conf

	if grep -q "^${key}:" "$file"; then
		sed -i "s#^${key}:.*#${key}: ${value}#" "$file"
	else
		printf '%s: %s\n' "$key" "$value" >> "$file"
	fi
}

set_acng_option CacheDir /dl/debs
set_acng_option LogDir /work/qemu-host/apt-cacher-ng
set_acng_option Port 3142
set_acng_option BindAddress 127.0.0.1
set_acng_option DlMaxRetries 10

cat > /etc/systemd/system/ds-serial-agent.service <<'SERVICE'
[Unit]
Description=distro-seed serial agent
After=systemd-modules-load.service

[Service]
Type=simple
Restart=always
RestartSec=1
StandardOutput=journal+console
StandardError=journal+console
ExecStart=/usr/local/sbin/ds-start-serial-agent

[Install]
WantedBy=multi-user.target
SERVICE

cat > /usr/local/sbin/ds-start-serial-agent <<'AGENTSTART'
#!/bin/bash
set -eu

echo "Starting distro-seed serial agent"
modprobe virtio_console 2>/dev/null || true

find_control_dev() {
	if [ -e /dev/virtio-ports/ds-control ]; then
		printf '%s\n' /dev/virtio-ports/ds-control
		return 0
	fi

	for name_file in /sys/class/virtio-ports/*/name; do
		[ -r "$name_file" ] || continue
		if [ "$(cat "$name_file")" = "ds-control" ]; then
			dev="/dev/$(basename "$(dirname "$name_file")")"
			if [ -e "$dev" ]; then
				printf '%s\n' "$dev"
				return 0
			fi
		fi
	done

	return 1
}

for _ in $(seq 1 120); do
	if control_dev="$(find_control_dev)"; then
		echo "Using distro-seed control port ${control_dev}"
		exec /usr/local/sbin/ds-serial-agent <>"$control_dev" >&0 2>&1
	fi
	echo "Waiting for distro-seed control port"
	sleep 1
done

echo "ds-control virtio port did not appear" >&2
find /sys/class/virtio-ports -maxdepth 2 -type f -print -exec sh -c 'printf "%s: " "$1"; cat "$1" 2>/dev/null || true; echo' sh {} \; 2>/dev/null || true
exit 1
AGENTSTART
chmod 755 /usr/local/sbin/ds-start-serial-agent

systemctl enable ds-serial-agent.service
systemctl disable --now apt-cacher-ng.service || true
systemctl mask apt-cacher-ng.service || true
mkdir -p /cache /dl /work /src
mkdir -p /etc/default/grub.d /var/lib/distro-seed
cat > /etc/default/grub.d/distro-seed-console.cfg <<'GRUB'
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX console=ttyS0,115200n8"
GRUB
update-grub || true
touch /var/lib/distro-seed/vm-ready
EOF

(
	cd "$BUILD_DIR/initrd-overlay"
	cp ../preseed.cfg preseed.cfg
	cp "${DS_HOST_ROOT_PATH}/common/vm/ds-serial-agent" ds-serial-agent
	cp ../ds-late-command.sh ds-late-command.sh
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
	-drive "if=virtio,file=${BASE_IMAGE},format=qcow2" \
	-cdrom "$ISO" \
	-netdev user,id=net0 \
	-device virtio-net-pci,netdev=net0 \
	-no-shutdown \
	-qmp "unix:${QMP_SOCKET},server=on,wait=off" \
	-monitor none \
	-serial stdio

printf '%s\n' "$CACHE_KEY" > "$KEY_FILE"
rm -rf "$BUILD_DIR" "${QEMU_DIR}/runtime.qcow2"
common/host/store_cache_obj.sh "$CACHE_KEY" "$QEMU_DIR"
