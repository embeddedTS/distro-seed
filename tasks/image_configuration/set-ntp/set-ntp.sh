#!/bin/bash -e

cat <<EOF > /etc/systemd/system/timesyncd.conf
[Time]
NTP=$CONFIG_DS_SET_NTPSERVER_PROVIDER
EOF
