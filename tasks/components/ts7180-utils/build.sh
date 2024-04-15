#!/bin/bash -e

SOURCE="$DS_WORK/components/ts7180-utils/"

cd "$SOURCE"

./autogen.sh
sed -i 's@bin_PROGRAMS = tshwctl load_fpga silabs get-opt@bin_PROGRAMS = tshwctl silabs get-opt@' src/Makefile.am
./configure --host="$AUTOTOOLS_HOST" --prefix="${DS_OVERLAY}/usr/local/"
make -j"$(nproc --all)" && make install
