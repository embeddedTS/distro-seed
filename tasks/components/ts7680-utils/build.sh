#!/bin/bash -e

SOURCE="$DS_WORK/components/ts7680-utils/"

cd "$SOURCE"

patch -p1 < "$DS_TASK_PATH/files/*.patch"

./autogen.sh
./configure --host="$AUTOTOOLS_HOST" --prefix="${DS_OVERLAY}/usr/local/"
make -j"$(nproc --all)" && make install
