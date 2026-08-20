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

## Kernel patches

To patch the fetched kernel source, set `DS_KERNEL_PATCH_DIR` to a directory
containing `*.patch` files:

```
CONFIG_DS_KERNEL_PATCH_DIR="patches/linux-lts"
```

Paths relative to the distro-seed checkout are resolved from its root. Absolute
paths are also accepted. Patches are applied in lexical filename order, so use
numeric prefixes when ordering matters:

```
patches/linux-lts/
  0001-enable-board-feature.patch
  0002-fix-board-regulator.patch
```

The patch task uses `git apply`; it accepts standard unified diffs and the diff
payload from `git format-patch` output. Patches are applied to distro-seed's
per-build copy of the kernel source, never the local repository named by
`DS_KERNEL_PROVIDER_GIT_URL`. That working copy is intentionally modified; no
commits are created and the source copy is discarded by the normal work cleanup.
