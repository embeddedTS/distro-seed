#!/bin/bash -e

# Create startup
cat << EOF > /etc/systemd/system/tssilomon.service
[Unit]
Description=TS-SILO Supercapacitor Monitor Daemon

[Service]
Type=simple
ExecStart=/bin/bash /usr/local/bin/tssilomon

[Install]
WantedBy=multi-user.target
EOF

systemctl enable tssilomon.service
