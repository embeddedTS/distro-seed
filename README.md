# distro-seed
## What is Distro-seed?
distro-seed is a tool to generate a Debian based distribution image for embedded targets, similar to buildroot but using Debian packages. Right now this only targets cross platform targets like armhf/armel/arm64.

This performs a series of tasks on a debian-based rootfs to generate the image. The basic image is configured through a Kconfig system. Distro-seed provides hooks that can be used to apply overlays, execute commands in the target image, or otherwise update compile software for the target image.

Distro seed provides:
* Dependency resolution
* Debian packagelists (and further customization from the .config)
* Object and download caching

## Requirements
* x86_64 host with KVM access
* qemu-system-x86_64
* qemu-img
* xorriso
* cpio
* sha256sum
* python3
* python3-colorama
* python3-path
* python3-yaml
* python3-matplotlib
* python3-networkx

## Installing:
This will run from any x86_64 Linux distribution that supports KVM, QEMU, python3, and has a filesystem with unix permissions. KVM is required; qemu TCG fallback is not supported.

* From Ubuntu/Debian based distros:
```
apt-get update && apt-get install -y qemu-system-x86 qemu-utils xorriso cpio
```

* From Fedora/Redhat based distros:
```
dnf install qemu-system-x86 qemu-img xorriso cpio
```

On either distribution, next install distro-seed, the python requirements and check the dependencies:
```
git clone https://github.com/embeddedTS/distro-seed.git
cd distro-seed
pip3 install --user -r requirements.txt
make checkdeps # Verifies all execution requirements are met
```
## Generating a rootfs:
```
make tsimx6_debian_12_x11_defconfig
make
# The resulting image will be in work/output/
```

The first build creates a shared Debian 13 VM from the Debian netinst ISO. The ISO is cached in `dl/blob`, and the installed VM is cached from the literal `Debian 13` string plus `packagelist-vm.txt`, so the same VM is reused for Debian and Ubuntu targets.

Useful shell targets:
```
make vm-shell
make cross-shell
make target-shell
```

Besides package downloads this will typically take around 5-30 minutes on a workstation to generate an image. This generates a simple rootfs that is capable of Networking, installs the kernel from git, and runs other setup.
