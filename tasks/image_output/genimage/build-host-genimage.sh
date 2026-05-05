#!/bin/bash -e

SOURCE="$DS_WORK/components/host-genimage/"
CACHE_KEY=$(/src/common/host/gen_cache_key.sh)

if ! /src/common/host/fetch_cache_obj.sh "$CACHE_KEY" "$SOURCE"; then
    (
        cd "$SOURCE"
        ./autogen.sh
        ./configure
        make -j"$(nproc --all)"
    )
    /src/common/host/store_cache_obj.sh "$CACHE_KEY" "$SOURCE"
fi
