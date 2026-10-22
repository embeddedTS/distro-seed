# Booting QEMU images

Run these commands from the repository root after completing the
[build prerequisites](../README.md). The launchers require
`qemu-system-arm` for ARMHF or `qemu-system-aarch64` for ARM64.

## ARMHF quick start

Build and boot a minimal Debian 13 ARMHF image:

```sh
make virtarmhf_debian_13_minimal_defconfig
make
./scripts/boot-qemu-armhf.sh
```

## ARM64 quick start

Build and boot a minimal Debian 13 ARM64 image:

```sh
make virtarm64_debian_13_minimal_defconfig
make
./scripts/boot-qemu-arm64.sh
```

Both launchers default to `work/output/rootfs.ext4`. Each build replaces that
output, so use the launcher matching the image you just built. Copy the image
elsewhere before another build if you want to keep it.

## Graphics and other images

Pass an image path to boot a saved image. Add `--graphics` when booting a
graphical image, such as one built with a `_weston_defconfig` or
`_x11_defconfig`:

```sh
./scripts/boot-qemu-arm64.sh --graphics path/to/rootfs.ext4
./scripts/boot-qemu-armhf.sh --graphics path/to/rootfs.ext4
```

Headless mode uses the terminal for the serial console. `--graphics` opens a
GTK window with a virtio GPU, keyboard, and tablet while keeping the serial
console in the terminal. A desktop or compositor must be installed in the
image to run graphical applications.

The host needs the matching QEMU system emulator and, for graphics, its GTK
display backend, plus `guestfish` (Debian/Ubuntu package `libguestfs-tools`).
The scripts extract the kernel and initrd through a read-only guestfish appliance
without sudo, following the symlinks in `/` or `/boot`. Run `make checkdeps` to
check the required tools. QEMU writes directly to the supplied image, so guest
changes persist.

Shut down with `poweroff` inside the guest. Ctrl-A followed by X exits QEMU
immediately. Temporary kernel and initrd copies are removed on exit.

Architecture settings live in the two launchers; shared options and image
handling live in `lib/boot-qemu.sh`.
