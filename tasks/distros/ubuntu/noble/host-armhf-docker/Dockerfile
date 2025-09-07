# syntax = docker/dockerfile:1.2

FROM ubuntu:noble

# Set up locales
RUN apt-get update && apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && echo 'LANG="en_US.UTF-8"'>/etc/default/locale && dpkg-reconfigure --frontend=noninteractive locales &&     update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Set up common docker packages
RUN apt-get update && apt-get install -y aptitude autogen automake bash bc bison build-essential bzip2 ca-certificates cmake curl fakeroot file flex git gzip kmod libconfuse-dev libncursesw5-dev libssl-dev libtool lzop lz4 make meson mmdebstrap ncurses-dev pkg-config qemu-user-static rsync runit u-boot-tools vim wget xz-utils

# Set default ubuntu sources to i386/amd64:
RUN sed -i '/Components: .*/a \Architectures: amd64 i386' /etc/apt/sources.list.d/ubuntu.sources
RUN echo "Types: deb\n\
URIs: http://ports.ubuntu.com/\n\
Suites: noble noble-updates noble-backports\n\
Components: main universe restricted multiverse\n\
Architectures: armhf\n\
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg" > /etc/apt/sources.list.d/ports.sources
RUN dpkg --add-architecture armhf
RUN apt-get update
RUN apt-get install -y libgpiod-dev:armhf libc6-dev-armhf-cross libstdc++-12-dev-armhf-cross gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf libinput-dev:armhf libiio-dev:armhf

# For linux cross compile
ENV CROSS_COMPILE=arm-linux-gnueabihf-
ENV ARCH=arm
ENV AUTOTOOLS_HOST=arm-linux-gnueabihf
ENV PKG_CONFIG_PATH=/usr/lib/arm-linux-gnueabihf/pkgconfig:/usr/share/pkgconfig
ENV PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig
ENV PKG_CONFIG_SYSROOT_DIR=/
ENV MESON_CROSS="/meson.cross"
RUN echo '[binaries]' > /meson.cross \
    && echo "c = 'arm-linux-gnueabihf-gcc'" >> /meson.cross \
    && echo "cpp = 'arm-linux-gnueabihf-g++'" >> /meson.cross \
    && echo "ar = 'arm-linux-gnueabihf-ar'" >> /meson.cross \
    && echo "strip = 'arm-linux-gnueabihf-strip'" >> /meson.cross \
    && echo "pkgconfig = 'arm-linux-gnueabihf-pkg-config'" >> /meson.cross
ENV CMAKE_CROSS="/cross.cmake"
RUN echo "set(CMAKE_SYSTEM_NAME Linux)" > /cross.cmake \
    && echo "set(CMAKE_C_COMPILER arm-linux-gnueabihf-gcc)" >> /cross.cmake \
    && echo "set(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++)" >> /cross.cmake \
    && echo "set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)" >> /cross.cmake \
    && echo "set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)" >> /cross.cmake \
    && echo "set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)" >> /cross.cmake \
    && echo "set(PKG_CONFIG_EXECUTABLE arm-linux-gnueabihf-pkg-config)" >> /cross.cmake

# Set PS1 to include docker name:
ENV chrootname armhf_ubuntu_noble
RUN echo "PS1='${chrootname}\[\033[01;32m\]@\H\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /etc/bash.bashrc
