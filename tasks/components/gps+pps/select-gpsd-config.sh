#!/bin/bash -e
#
# select-gpsd-config.sh - auto-create a service to run select_gps_config at boot
#
# tasks/components/gps+pps
#

servicename=gps_config.service
servicefile="/etc/systemd/system/${servicename}"
runscript="/usr/local/bin/select_gps_config"

cat <<EOF > "$servicefile"
[Unit]
Description=Link to an appropriate gpsd config
ConditionPathExists=!/run/gpsd.config

[Service]
Type=oneshot
ExecStart=${runscript}

[Install]
WantedBy=multi-user.target
EOF

ln -s /run/gpsd.config /etc/default/gpsd

systemctl enable "$servicename"
