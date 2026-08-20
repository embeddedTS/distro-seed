# Kernel configuration

`DS_KERNEL_DEFCONFIG` selects the defconfig passed to the kernel's `make`
command. To add configuration without maintaining a full replacement
defconfig, set `DS_KERNEL_CONFIG_FRAGMENT_FILES` to a whitespace-separated,
ordered list of kernel configuration fragments:

```
CONFIG_DS_KERNEL_CONFIG_FRAGMENT_FILES="configs/kernel/enable-can.config configs/kernel/debug.config"
```

Paths relative to the distro-seed checkout are resolved from its root. Absolute
paths are also accepted. Fragment paths cannot contain whitespace.

distro-seed first applies `DS_KERNEL_DEFCONFIG`, then merges each fragment in
the listed order using the kernel's `scripts/kconfig/merge_config.sh`. Later
fragments take precedence over earlier fragments. Finally it runs `make
olddefconfig` to resolve configuration dependencies before building the kernel.

Fragment files use normal kernel configuration syntax, for example:

```
CONFIG_CAN=y
CONFIG_CAN_MCP251X=m
# CONFIG_DEBUG_INFO is not set
```
