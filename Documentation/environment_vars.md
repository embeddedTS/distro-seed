Every script run by distro-seed has access to these core set of environment variables:

| Variable | Host | VM | Cross | Target | Description |
| - | - | - | - | - | - |
| DS_HOST_ROOT_PATH | X | X | X |   | Path to where distro-seed is checked out. This is `/src` inside the VM and cross chroot. |
| DS_DL             | X | X | X |   | Download directory. This is mounted as `/dl` inside the VM; apt-cacher-ng stores debs in `/dl/debs`. |
| DS_CACHE          | X | X | X |   | Cache directory. This is mounted as `/cache` inside the VM. |
| DS_WORK           | X | X | X |   | Work directory. This is mounted as `/work` inside the VM. |
| DS_DISTRO         | X | X | X | X | Distro name, eg "ubuntu" or "debian" |
| DS_RELEASE        | X | X | X | X | Release name, eg "bullseye", or "jammy" |
| DS_RELEASE_NUM    | X | X | X | X | Release number, eg "12", or "23.04" |
| DS_TARGET_ARCH    | X | X | X | X | Architecture name, eg "armhf" or "armel" |
| DS_OVERLAY        | X | X | X |   | Path to the task overlay. VM and cross tasks receive a temporary overlay path that is archived into `work/overlays/` only when it contains files. |
| DS_TASK_PATH      | X | X | X |   | Path to the manifest being executed |

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
