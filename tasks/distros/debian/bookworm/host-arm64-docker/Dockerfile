# syntax = docker/dockerfile:1.2

FROM debian:bookworm

# Set up locales
RUN apt-get update && apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && echo 'LANG="en_US.UTF-8"'>/etc/default/locale && dpkg-reconfigure --frontend=noninteractive locales &&     update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Set up common docker packages
RUN apt-get update && apt-get install -y strace autogen automake bash bc bison build-essential bzip2 ca-certificates curl fakeroot file flex git gzip kmod libconfuse-dev libncursesw5-dev libssl-dev libtool lzop lz4 make meson mmdebstrap ncurses-dev pkg-config qemu-user-static rsync runit u-boot-tools vim wget xz-utils

# Install arch specific packages:
RUN dpkg --add-architecture arm64
RUN apt-get update && apt-get install -y gcc-aarch64-linux-gnu libc6-dev:arm64 libgpiod-dev:arm64

# Cross compile variables:
ENV CROSS_COMPILE=aarch64-linux-gnu-
ENV ARCH=arm64
ENV AUTOTOOLS_HOST=aarch64-linux-gnu
ENV PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig
ENV PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig
ENV PKG_CONFIG_SYSROOT_DIR=/
ENV MESON_CROSS="/meson.cross"
RUN echo '[binaries]' > /meson.cross \
    && echo "c = 'aarch64-linux-gnu-gcc'" >> /meson.cross \
    && echo "cpp = 'aarch64-linux-gnu-g++'" >> /meson.cross \
    && echo "ar = 'aarch64-linux-gnu-ar'" >> /meson.cross \
    && echo "strip = 'aarch64-linux-gnu-strip'" >> /meson.cross \
    && echo "pkgconfig = 'aarch64-linux-gnu-pkg-config'" >> /meson.cross

ENV CMAKE_CROSS="/cross.cmake"
RUN echo "set(CMAKE_SYSTEM_NAME Linux)" > /cross.cmake \
    && echo "set(CMAKE_C_COMPILER 'aarch64-linux-gnu-gcc)" >> /cross.cmake \
    && echo "set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)" >> /cross.cmake \
    && echo "set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)" >> /cross.cmake \
    && echo "set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)" >> /cross.cmake \
    && echo "set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)" >> /cross.cmake \
    && echo "set(PKG_CONFIG_EXECUTABLE aarch64-linux-gnu-pkg-config)" >> /cross.cmake

# Set PS1 to include docker name:
ENV chrootname arm64_debian_bookworm
RUN echo "PS1='${chrootname}\[\033[01;32m\]@\H\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /etc/bash.bashrc
