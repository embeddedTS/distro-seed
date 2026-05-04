Every script run by distro-seed has access to these core set of environment variables:

| Variable | Host | VM | Cross | Target | Description |
| - | - | - | - | - | - |
| DS_HOST_ROOT_PATH | X | X | X |   | Path to where distro-seed is checked out. This is `/src` inside the VM and cross chroot. |
| DS_DL             | X | X | X |   | Download directory. This is mounted as `/dl` inside the VM; apt-cacher-ng stores debs in `/dl/debs`. |
| DS_CACHE          | X | X | X |   | Cache directory. This is mounted as `/cache` inside the VM. |
| DS_WORK           | X | X | X |   | Work directory. This is mounted as `/work` inside the VM. |
| DS_TARGET_ROOTFS  |   | X | X |   | VM-local target rootfs path. This defaults to `/vm-work/rootfs` and is not shared directly with the host. |
| DS_DISTRO         | X | X | X | X | Distro name, eg "ubuntu" or "debian" |
| DS_RELEASE        | X | X | X | X | Release name, eg "bullseye", or "jammy" |
| DS_RELEASE_NUM    | X | X | X | X | Release number, eg "12", or "23.04" |
| DS_TARGET_ARCH    | X | X | X | X | Architecture name, eg "armhf" or "armel" |
| DS_OVERLAY        | X | X | X |   | Temporary package payload root for this task. If it contains files, distro-seed turns it into a generated local Debian package before installing it into the target rootfs. |
| DS_OVERLAY_CONTROL | X | X | X |   | Temporary package control directory for this task. Supports optional `preinst`, `postinst`, `prerm`, `postrm`, and `version` files for the generated local Debian package. |
| DS_TASK_PATH      | X | X | X |   | Path to the manifest being executed |

`host`, `vm`, and `cross` tasks can install target filesystem content into
`DS_OVERLAY`. Distro-seed stores that content as metadata-preserving tar
artifacts under `work/package-inputs/`, builds a local `.deb` in the VM, and
installs it into the target rootfs in task order. These tasks run with umask
`022`, and package payloads are built with root ownership by default. If a task
needs intentional non-root ownership or other target-side setup, add an
executable maintainer script through `DS_OVERLAY_CONTROL`, usually `postinst`.

If `DS_OVERLAY_CONTROL/version` exists, its first line is used as the generated
package version. If it does not exist, distro-seed uses `0.0.1`.

The VM also has a native ext4 scratch disk mounted at `/vm-work`. It is not a host-shared directory, and is used for build trees that need normal Linux filesystem behavior. For example, kernel fetch tasks create source tar archives under `work/`, and the VM unpacks them into `/vm-work` before compiling.

The rest of the CONFIG options are also exported into each environment. For example a bool option in Kconfig will be y or n.  If a config file contains:
```
CONFIG_DS_JOURNAL_DISABLE_LOGS=y
```
This will be exported so it can be checked in any task with:
```
#!/bin/bash

if [ "$CONFIG_DS_JOURNAL_DISABLE_LOGS" = "y" ]; then
    echo "Option is enabled"
fi
```
Kconfig string values output the same way as bools, but with their value directly.
For example, the Kconfig option:
```
config DS_JOURNAL_SIZE_VALUE
	string "Set Journal size limit"
```
Is available in a script with:
```
echo "$CONFIG_DS_JOURNAL_SIZE_VALUE"
```

All config options are prefixed with "DS_" to avoid colliding with other Kconfig projects that might be built under distro-seed.
