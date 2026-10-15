#!/bin/bash -e

install -d "$DS_OVERLAY/etc/apt/sources.list.d/"
install -m 644 "${DS_TASK_PATH}/files/ubuntu.sources" \
	"$DS_OVERLAY/etc/apt/sources.list.d/ubuntu.sources"
install -m 644 "${DS_TASK_PATH}/files/sources.list" "$DS_OVERLAY/etc/apt/sources.list"
