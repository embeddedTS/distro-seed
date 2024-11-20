#!/bin/bash -e

# Create startup
cat << EOF > /etc/systemd/system/idleinject.service
[Unit]
Description=Monitor CPU temperatures and inject idle cycles if nearing max temperature

[Service]
Type=simple
ExecStart=/usr/local/bin/idleinject

[Install]
WantedBy=multi-user.target
EOF

systemctl enable idleinject.service
