#!/bin/bash -e

cd "${DS_TASK_WORK}"

./autogen.sh
./configure --host="$AUTOTOOLS_HOST" --prefix="${DS_OVERLAY}/usr/local/"
make -j"$(nproc --all)" && make install
