#!/bin/bash -e

SOURCE="$DS_STAGING"

cd "$SOURCE"

./autogen.sh
./configure --host="$AUTOTOOLS_HOST" --prefix="${DS_OVERLAY}/usr/local/"
make -j"$(nproc --all)" && make install
