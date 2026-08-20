# Kernel configuration

`DS_KERNEL_DEFCONFIG` selects the in-tree defconfig passed to the kernel's
`make` command. To use an out-of-tree defconfig instead, set
`DS_KERNEL_DEFCONFIG_FILE`:

```
CONFIG_DS_KERNEL_DEFCONFIG_FILE="configs/kernel/my-board_defconfig"
```

An out-of-tree defconfig takes precedence over `DS_KERNEL_DEFCONFIG`. Paths
relative to the distro-seed checkout are resolved from its root. Absolute paths
are also accepted.

To add configuration without maintaining a full replacement defconfig, set
`DS_KERNEL_CONFIG_FRAGMENT_FILES` to a whitespace-separated, ordered list of
kernel configuration fragments:

```
CONFIG_DS_KERNEL_CONFIG_FRAGMENT_FILES="configs/kernel/enable-can.config configs/kernel/debug.config"
```

Paths relative to the distro-seed checkout are resolved from its root. Absolute
paths are also accepted. Fragment paths cannot contain whitespace.

distro-seed first applies the out-of-tree defconfig when
`DS_KERNEL_DEFCONFIG_FILE` is set; otherwise it applies
`DS_KERNEL_DEFCONFIG`. It then merges each fragment in the listed order using
the kernel's `scripts/kconfig/merge_config.sh`. Later fragments take precedence
over earlier fragments. Finally it runs `make olddefconfig` to resolve
configuration dependencies before building the kernel.

Fragment files use normal kernel configuration syntax, for example:

```
CONFIG_CAN=y
CONFIG_CAN_MCP251X=m
# CONFIG_DEBUG_INFO is not set
```
