#!/bin/bash -e

SOURCE="$DS_STAGING"

cd "$SOURCE"

mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX="${DS_OVERLAY}/usr" -DBUILD_SHARED_LIBS=TRUE -DCMAKE_TOOLCHAIN_FILE="${CMAKE_CROSS}"
make install
