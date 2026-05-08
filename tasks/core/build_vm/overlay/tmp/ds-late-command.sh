#!/bin/bash -e

cat >> /etc/apt-cacher-ng/acng.conf <<'EOF'
CacheDir: /dl/debs
LogDir: /work/qemu-host/apt-cacher-ng
Port: 3142
BindAddress: 127.0.0.1
DlMaxRetries: 10
EOF

venv=/opt/distro-seed/venv
requirements=/tmp/ds-vm-requirements.txt
install -d "$(dirname "${venv}")"
python3 -m venv "${venv}"
"${venv}/bin/python" -m pip install --no-cache-dir -r "${requirements}"

systemctl enable ds-vm-runtime-setup.service
systemctl enable apt-cacher-ng.service
systemctl enable ds-serial-agent.service
mkdir -p /cache /dl /work /src /vm-work
cat >> /etc/fstab <<'EOF'
cache /cache 9p trans=virtio,version=9p2000.L,msize=104857600,nofail 0 0
dl /dl 9p trans=virtio,version=9p2000.L,msize=104857600,nofail 0 0
work /work 9p trans=virtio,version=9p2000.L,msize=104857600,nofail 0 0
src /src 9p trans=virtio,version=9p2000.L,msize=104857600,ro,nofail 0 0
LABEL=ds-vm-work /vm-work ext4 noatime,nofail 0 2
EOF

# Regenerate grub.cfg after adding the serial console drop-in from the overlay.
update-grub || true
