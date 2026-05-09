#!/bin/bash -e

KEY_URL="https://apt.embeddedts.com/embeddedts.asc"
KEY_SHA256="ce85aaf704e7798f98f9098b9f1846bc4aba138ed0d1e0bf98c0f8d9c6b7a973"

common/host/fetch_blob.sh "$KEY_URL" "${DS_TASK_WORK}/embeddedts.asc" "$KEY_SHA256"

cat <<EOF | tee "${DS_TASK_WORK}/embeddedts.sources"
Types: deb
URIs: http://apt.embeddedts.com
Suites: $DS_RELEASE
Components: main
Signed-By: /etc/apt/keyrings/embeddedts.asc
EOF

install -d "$DS_OVERLAY/etc/apt/sources.list.d"
install -m 444 "${DS_TASK_WORK}/embeddedts.sources" "$DS_OVERLAY/etc/apt/sources.list.d/embeddedts.sources"
install -d "$DS_OVERLAY/etc/apt/keyrings"
install -m 444 "${DS_TASK_WORK}/embeddedts.asc" "$DS_OVERLAY/etc/apt/keyrings/embeddedts.asc"
