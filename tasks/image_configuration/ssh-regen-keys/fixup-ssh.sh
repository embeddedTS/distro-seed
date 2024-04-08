#!/bin/bash -e

# This script is run on every image that is generated.
# If the ssh server is installed, we add a service that regenerates keys on the first boot.
# we also remove any generated keys at this point so we dont distribute common keys to
# many boards

if [ ! -e "/usr/sbin/sshd" ]; then
    echo "ssh not installed"
    exit 0
fi

# Remove any keys that might otherwise be shipped:
(
    set +e
    rm -rf /etc/ssh/*_key.pub
    rm -rf /etc/ssh/*_key
)

servicename=sshfirstboot.service
servicefile="/etc/systemd/system/${servicename}"
runscript="/usr/local/bin/regen_ssh_keys"

cat <<EOF > "$servicefile"
[Unit]
Description=Regenerate SSH keys for first boot
Before=ssh.service

[Service]
Type=oneshot
ExecStart=${runscript}

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > "$runscript"
#!/bin/bash

if [ -e "/usr/sbin/sshd" ]; then
    ssh-keygen -A
fi

EOF

chmod a+x "$runscript"
systemctl enable "$servicename"
