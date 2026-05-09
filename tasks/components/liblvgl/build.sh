#!/bin/bash -e

cd "${DS_TASK_WORK}"

mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX="${DS_OVERLAY}/usr" -DBUILD_SHARED_LIBS=TRUE -DCMAKE_TOOLCHAIN_FILE="${CMAKE_CROSS}"
make install
