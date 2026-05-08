#!/bin/bash
set -Eeuo pipefail

CROSS_ROOT=/tmp/distro-seed-cross
STAMP="${CROSS_ROOT}/.distro-seed-cross-${DS_DISTRO}-${DS_RELEASE}-${DS_TARGET_ARCH}"
DISTRO_CROSS_SETUP="/src/tasks/distros/${DS_DISTRO}/${DS_RELEASE}/cross-setup.sh"

fail() {
	echo "cross setup failed: $*" >&2
	exit 1
}

on_error() {
	status=$?
	echo "cross setup failed at line ${BASH_LINENO[0]} with status ${status}" >&2
	exit "$status"
}
trap on_error ERR

mount_cross_runtime() {
	mkdir -p "$CROSS_ROOT/proc" "$CROSS_ROOT/sys" "$CROSS_ROOT/dev" "$CROSS_ROOT/dev/pts"
	mountpoint -q "$CROSS_ROOT/proc" || mount -t proc proc "$CROSS_ROOT/proc"
	mountpoint -q "$CROSS_ROOT/sys" || mount -t sysfs sysfs "$CROSS_ROOT/sys"
	mountpoint -q "$CROSS_ROOT/dev" || mount --bind /dev "$CROSS_ROOT/dev"
	mountpoint -q "$CROSS_ROOT/dev/pts" || mount --bind /dev/pts "$CROSS_ROOT/dev/pts"
}

unmount_cross_runtime() {
	for path in "$CROSS_ROOT/dev/pts" "$CROSS_ROOT/dev" "$CROSS_ROOT/sys" "$CROSS_ROOT/proc"; do
		if mountpoint -q "$path"; then
			umount "$path"
		fi
	done
}

load_distro_cross_setup() {
	if [[ ! -r "$DISTRO_CROSS_SETUP" ]]; then
		fail "unsupported cross distro/release ${DS_DISTRO}/${DS_RELEASE}; missing ${DISTRO_CROSS_SETUP}"
	fi
	# shellcheck source=/dev/null
	source "$DISTRO_CROSS_SETUP"
}

collect_packages() {
	PKGS="apt ca-certificates gnupg locales build-essential autogen automake bash bc bison bzip2 cmake curl fakeroot file flex git gzip kmod libconfuse-dev libncursesw5-dev libssl-dev libtool lz4 lzop make meson mmdebstrap ncurses-dev pkg-config rsync runit strace u-boot-tools vim wget xz-utils zstd"
	if [[ -d /work/packagelist-cross ]]; then
		EXTRA="$(sed -e 's/#.*$//' -e '/^$/d' /work/packagelist-cross/* 2>/dev/null | tr -s '[:space:]' '\n' | sort -u | paste -sd' ' -)"
		PKGS="${PKGS} ${EXTRA}"
	fi
}

setup_cross_tools() {
	case "$DS_TARGET_ARCH" in
		armhf)
			CROSS_PKGS="gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf libc6-dev:armhf libgpiod-dev:armhf"
			triplet=arm-linux-gnueabihf
			arch=arm
			;;
		armel)
			CROSS_PKGS="gcc-arm-linux-gnueabi g++-arm-linux-gnueabi libc6-dev:armel libgpiod-dev:armel"
			triplet=arm-linux-gnueabi
			arch=arm
			;;
		arm64)
			CROSS_PKGS="gcc-aarch64-linux-gnu g++-aarch64-linux-gnu libc6-dev:arm64 libgpiod-dev:arm64"
			triplet=aarch64-linux-gnu
			arch=arm64
			;;
		*)
			fail "unsupported target architecture ${DS_TARGET_ARCH}"
			;;
	esac
}

APT_CHROOT_OPTS=(
	-o Acquire::http::Proxy=http://127.0.0.1:3142
	-o Acquire::http::Timeout=120
	-o Acquire::Retries=5
	-o Acquire::Queue-Mode=access
	-o Acquire::http::Pipeline-Depth=0
	-o Acquire::Languages=none
)

if [[ -e "$STAMP" ]]; then
	mount_cross_runtime
	exit 0
fi

load_distro_cross_setup
collect_packages
setup_cross_tools

[[ -n "${CROSS_MIRROR:-}" ]] || fail "distro cross setup did not set CROSS_MIRROR"
[[ -n "${CROSS_COMPONENTS:-}" ]] || fail "distro cross setup did not set CROSS_COMPONENTS"
[[ -n "${CROSS_KEYRING:-}" ]] || fail "distro cross setup did not set CROSS_KEYRING"
[[ -r "$CROSS_KEYRING" ]] || fail "required keyring ${CROSS_KEYRING} is missing; rebuild the VM cache after updating tasks/core/build_vm/packagelist-vm.txt"

declare -F write_cross_sources >/dev/null || fail "distro cross setup did not define write_cross_sources"

unmount_cross_runtime
rm -rf "$CROSS_ROOT"
mkdir -p "$CROSS_ROOT"

mmdebstrap \
	--variant=custom \
	--architectures=amd64 \
	--components="$CROSS_COMPONENTS" \
	--keyring="$CROSS_KEYRING" \
	--include='?essential' \
	--include='~prequired|~pimportant' \
	--include="$PKGS" \
	--aptopt='Acquire::http::Proxy "http://127.0.0.1:3142";' \
	--aptopt='Acquire::http::Timeout "120";' \
	--aptopt='Acquire::Retries "5";' \
	--aptopt='Acquire::Queue-Mode "access";' \
	--aptopt='Acquire::http::Pipeline-Depth "0";' \
	--aptopt='Acquire::Languages "none";' \
	"$DS_RELEASE" "$CROSS_ROOT" "$CROSS_MIRROR"

[[ -x "$CROSS_ROOT/usr/bin/dpkg" ]] || fail "mmdebstrap did not create a usable cross root at ${CROSS_ROOT}"

mount_cross_runtime
chroot "$CROSS_ROOT" dpkg --add-architecture "$DS_TARGET_ARCH"
install -d "$CROSS_ROOT/etc/apt" "$CROSS_ROOT/etc/apt/sources.list.d"
write_cross_sources "$CROSS_ROOT"

chroot "$CROSS_ROOT" apt-get "${APT_CHROOT_OPTS[@]}" update
DEBIAN_FRONTEND=noninteractive chroot "$CROSS_ROOT" apt-get "${APT_CHROOT_OPTS[@]}" install -y --no-install-recommends $CROSS_PKGS

cat > "$CROSS_ROOT/distro-seed-cross-env" <<EOF_ENV
export CROSS_COMPILE=${triplet}-
export ARCH=${arch}
export AUTOTOOLS_HOST=${triplet}
export PKG_CONFIG_PATH=/usr/lib/${triplet}/pkgconfig:/usr/share/pkgconfig
export PKG_CONFIG_LIBDIR=/usr/lib/${triplet}/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=/
export MESON_CROSS=/meson.cross
export CMAKE_CROSS=/cross.cmake
EOF_ENV

cat > "$CROSS_ROOT/meson.cross" <<EOF_MESON
[binaries]
c = '${triplet}-gcc'
cpp = '${triplet}-g++'
ar = '${triplet}-ar'
strip = '${triplet}-strip'
pkgconfig = '${triplet}-pkg-config'
EOF_MESON

cat > "$CROSS_ROOT/cross.cmake" <<EOF_CMAKE
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_C_COMPILER ${triplet}-gcc)
set(CMAKE_CXX_COMPILER ${triplet}-g++)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(PKG_CONFIG_EXECUTABLE ${triplet}-pkg-config)
EOF_CMAKE

touch "$STAMP"
