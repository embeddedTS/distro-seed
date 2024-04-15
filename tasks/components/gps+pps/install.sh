#!/bin/bash -e

install -d "$DS_OVERLAY/usr/share/gps+pps/"

# install derefrences symlinks, so use cp to preserve symlinks here:
cp --no-dereference "$DS_TASK_PATH"/files/* "$DS_OVERLAY/usr/share/gpsd+pps/"
chmod 644 $DS_OVERLAY/usr/share/gps+pps/*

install -d "$DS_OVERLAY/usr/local/bin/"
install ${DS_TASK_PATH}/scripts/select_gpsd_config.sh "$DS_OVERLAY/usr/local/bin/select_gpsd_config"
