#!/bin/bash -e

SOURCE="${DS_WORK}/components/ts4100-utils/"

cd "${SOURCE}"

./autogen.sh
./configure --host="$AUTOTOOLS_HOST" --prefix="${DS_OVERLAY}/usr/local/"
make -j"$(nproc --all)" && make install

cd "${SOURCE}/src/zpu"
# TODO: The compiler name is a bit of a magic number that I don't know how
# to best handle dynamically. For now, when updating release, this needs to
# change too
PATH=$PATH:"${DS_WORK}/x86_64-zpu-elf-gcc-3.4.2/bin/" make
install -d "${DS_OVERLAY}/usr/local/bin/zpu"
install -m 0644 *.bin "${DS_OVERLAY}/usr/local/bin/zpu/"
