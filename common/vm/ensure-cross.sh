#!/bin/bash -e

CROSS_ROOT=/tmp/distro-seed-cross
STAMP="${CROSS_ROOT}/.distro-seed-cross-${DS_DISTRO}-${DS_RELEASE}-${DS_TARGET_ARCH}"

mount_cross_runtime() {
	mkdir -p "$CROSS_ROOT/proc" "$CROSS_ROOT/sys" "$CROSS_ROOT/dev" "$CROSS_ROOT/dev/pts"
	mountpoint -q "$CROSS_ROOT/proc" || mount -t proc proc "$CROSS_ROOT/proc"
	mountpoint -q "$CROSS_ROOT/sys" || mount -t sysfs sysfs "$CROSS_ROOT/sys"
	mountpoint -q "$CROSS_ROOT/dev" || mount --bind /dev "$CROSS_ROOT/dev"
	mountpoint -q "$CROSS_ROOT/dev/pts" || mount --bind /dev/pts "$CROSS_ROOT/dev/pts"
}

unmount_cross_runtime() {
	for path in "$CROSS_ROOT/dev/pts" "$CROSS_ROOT/dev" "$CROSS_ROOT/sys" "$CROSS_ROOT/proc"; do
		mountpoint -q "$path" && umount "$path"
	done
}

if [[ -e "$STAMP" ]]; then
	mount_cross_runtime
	exit 0
fi

unmount_cross_runtime
rm -rf "$CROSS_ROOT"
mkdir -p "$CROSS_ROOT"

if [[ "$DS_DISTRO" == "debian" ]]; then
	MIRROR="${CONFIG_DS_CUSTOM_APT_URL:-http://deb.debian.org/debian}"
	COMPONENTS="main contrib non-free non-free-firmware"
	KEYRING="/usr/share/keyrings/debian-archive-keyring.gpg"
elif [[ "$DS_DISTRO" == "ubuntu" ]]; then
	MIRROR="${CONFIG_DS_CUSTOM_APT_URL:-http://archive.ubuntu.com/ubuntu}"
	COMPONENTS="main universe multiverse restricted"
	KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
else
	echo "Unsupported distro $DS_DISTRO" >&2
	exit 1
fi

PKGS="apt ca-certificates gnupg locales build-essential autogen automake bash bc bison bzip2 cmake curl fakeroot file flex git gzip kmod libconfuse-dev libncursesw5-dev libssl-dev libtool lz4 lzop make meson mmdebstrap ncurses-dev pkg-config rsync runit strace u-boot-tools vim wget xz-utils zstd"
APT_PROXY_OPTS=(
	-o Acquire::http::Proxy=http://127.0.0.1:3142
	-o Acquire::Retries=5
	-o Acquire::Queue-Mode=access
	-o Acquire::http::Pipeline-Depth=0
	-o Acquire::Languages=none
)
APT_CHROOT_OPTS=(
	-o Acquire::Retries=5
	-o Acquire::Queue-Mode=access
	-o Acquire::http::Pipeline-Depth=0
	-o Acquire::Languages=none
)

if [[ -d /work/packagelist-cross ]]; then
	EXTRA="$(sed -e 's/#.*$//' -e '/^$/d' /work/packagelist-cross/* 2>/dev/null | tr -s '[:space:]' '\n' | sort -u | paste -sd' ' -)"
	PKGS="${PKGS} ${EXTRA}"
fi

mmdebstrap \
	--variant=custom \
	--architectures=amd64 \
	--components="$COMPONENTS" \
	--keyring="$KEYRING" \
	--include='?essential' \
	--include='~prequired|~pimportant' \
	--include="$PKGS" \
	--aptopt='Acquire::http::Proxy "http://127.0.0.1:3142";' \
	--aptopt='Acquire::Retries "5";' \
	--aptopt='Acquire::Queue-Mode "access";' \
	--aptopt='Acquire::http::Pipeline-Depth "0";' \
	--aptopt='Acquire::Languages "none";' \
	"$DS_RELEASE" "$CROSS_ROOT" "$MIRROR"

mount_cross_runtime
chroot "$CROSS_ROOT" dpkg --add-architecture "$DS_TARGET_ARCH"

if [[ "$DS_DISTRO" == "debian" ]]; then
	cat > "$CROSS_ROOT/etc/apt/sources.list" <<EOF
deb [arch=amd64] ${MIRROR} ${DS_RELEASE} ${COMPONENTS}
deb [arch=${DS_TARGET_ARCH}] ${MIRROR} ${DS_RELEASE} main
EOF
elif [[ "$DS_DISTRO" == "ubuntu" ]]; then
	cat > "$CROSS_ROOT/etc/apt/sources.list" <<EOF
deb [arch=amd64] ${MIRROR} ${DS_RELEASE} ${COMPONENTS}
EOF
	cat > "$CROSS_ROOT/etc/apt/sources.list.d/ports.list" <<EOF
deb [arch=${DS_TARGET_ARCH}] http://ports.ubuntu.com/ubuntu-ports ${DS_RELEASE} main universe restricted multiverse
deb [arch=${DS_TARGET_ARCH}] http://ports.ubuntu.com/ubuntu-ports ${DS_RELEASE}-updates main universe restricted multiverse
deb [arch=${DS_TARGET_ARCH}] http://ports.ubuntu.com/ubuntu-ports ${DS_RELEASE}-backports main universe restricted multiverse
EOF
fi

case "$DS_TARGET_ARCH" in
	armhf)
		CROSS_PKGS="gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf libc6-dev:armhf libgpiod-dev:armhf"
		;;
	armel)
		CROSS_PKGS="gcc-arm-linux-gnueabi g++-arm-linux-gnueabi libc6-dev:armel libgpiod-dev:armel"
		;;
	arm64)
		CROSS_PKGS="gcc-aarch64-linux-gnu g++-aarch64-linux-gnu libc6-dev:arm64 libgpiod-dev:arm64"
		;;
	*)
		echo "Unsupported target architecture $DS_TARGET_ARCH" >&2
		exit 1
		;;
esac

chroot "$CROSS_ROOT" apt-get "${APT_CHROOT_OPTS[@]}" update
DEBIAN_FRONTEND=noninteractive chroot "$CROSS_ROOT" apt-get "${APT_CHROOT_OPTS[@]}" install -y --no-install-recommends $CROSS_PKGS

case "$DS_TARGET_ARCH" in
	armhf)
		triplet=arm-linux-gnueabihf
		arch=arm
		;;
	armel)
		triplet=arm-linux-gnueabi
		arch=arm
		;;
	arm64)
		triplet=aarch64-linux-gnu
		arch=arm64
		;;
esac

cat > "$CROSS_ROOT/distro-seed-cross-env" <<EOF
export CROSS_COMPILE=${triplet}-
export ARCH=${arch}
export AUTOTOOLS_HOST=${triplet}
export PKG_CONFIG_PATH=/usr/lib/${triplet}/pkgconfig:/usr/share/pkgconfig
export PKG_CONFIG_LIBDIR=/usr/lib/${triplet}/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=/
export MESON_CROSS=/meson.cross
export CMAKE_CROSS=/cross.cmake
EOF

cat > "$CROSS_ROOT/meson.cross" <<EOF
[binaries]
c = '${triplet}-gcc'
cpp = '${triplet}-g++'
ar = '${triplet}-ar'
strip = '${triplet}-strip'
pkgconfig = '${triplet}-pkg-config'
EOF

cat > "$CROSS_ROOT/cross.cmake" <<EOF
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_C_COMPILER ${triplet}-gcc)
set(CMAKE_CXX_COMPILER ${triplet}-g++)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(PKG_CONFIG_EXECUTABLE ${triplet}-pkg-config)
EOF

touch "$STAMP"
