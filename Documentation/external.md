# DS\_EXTERNAL project for out-of-tree changes

Support out-of-tree configurations, patches, tasks, etc. for distro-seed. This allows for customization of a platform specific BSP without the requirement of forking distro-seed and storing changes in the fork. The distro-seed repository can be included as a submodule (or some other directory outside of the DS\_EXTERNAL repo) and make commands forwarded to the distro-seed project and will include the `DS_EXTERNAL` variable pointing to the DS\_EXTERNAL repository.

## Features

The DS\_EXTERNAL variable is used to inform `distro-seed` where it can find certain files externally to use in preference over its own internal tree locations. An example directory structure of a DS\_EXTERNAL repository would look like:

```
+-- Kconfig
+-- Makefile
+-- configs/
|   +-- my_custom_distroseed_defconfig
|
+-- kernel_fragments/
|   +-- enable_driverA.fragment
|   +-- ...
|
+-- kernel_patches/
|   +-- 0001-add-driverA.patch
|   +-- ...
|
+-- tasks/
    +-- custom-tool/
        +-- Kconfig
        +-- script.sh
        +-- manifest.yaml
```

A DS\_EXTERNAL project can define:
- Any number of defconfigs[^1]
- Any number of tasks[^2]
- A folder of kernel configuration fragments[^3], patches[^3], or whole kernel defconfigs[^3]

## Quick start

A DS\_EXTERNAL project only needs a Makefile to forward `make` commands at the minimum. For example, a setup where a DS\_EXTERNAL repository uses `distro-seed.git` as a submodule in the project:

```make
export DS_EXTERNAL := $(CURDIR)

.DEFAULT_GOAL := all

%:
	$(MAKE) -C distro-seed $@
```

From the DS\_EXTERNAL root folder, `make` commands are sent to the distro-seed tree with the variable `DS_EXTERNAL` defined. The main scripts will add the `DS_EXTERNAL` path to their search.

## Defconfig files

In the DS\_EXTERNAL tree, create a folder named `configs/` and add any customized `distro-seed` defconfig files there. These are parsed as part of `make`.

## Kernel patches, defconfigs, and config fragments

In the DS\_EXTERNAL tree, these can be present in any number of arbitrarily named folders. Then in the defconfig, the variable `$(DS_EXTERNAL)` is used to inform the build scripts where to look for the folders.

For example, in the folder structure outlined above, the following CONFIG objects can be defined:

```mel
CONFIG_DS_KERNEL_PATCH_DIR="$(DS_EXTERNAL)/kernel_patches/"
CONFIG_DS_KERNEL_CONFIG_FRAGMENT_FILES="$(DS_EXTERNAL)/kernel_fragments/debug.fragment"
CONFIG_DS_KERNEL_DEFCONFIG_FILE="$(DS_EXTERNAL)/kernel_defconfig"
```

## Tasks

Tasks are supported in a DS\_EXTERNAL repository in the same way they are in the main `distro-seed` repository. The only setup required is a `Kconfig` file at the root of the DS\_EXTERNAL project to define the task `Kconfig` locations.

Tasks defined in the DS\_EXTERNAL repository all follow the same manifest format and have all build variables available to them.

For example, the `Kconfig` file in the root of the DS\_EXTERNAL project can include a custom task named `custom-tool`:

```mel
menu "External tasks"
rsource "tasks/custom-tool/Kconfig"
endmenu
```

The full `Kconfig` syntax is available and parsed by `distro-seed`.

[^1]: These must reside in a folder named `configs/`, any files here take precedent over files shipped in the `configs/` directory inside the main `distro-seed` tree.
[^2]: Tasks, ordering, locations, etc., are all parsed using `Kconfig` and follow the same requirements, and have same variable availability, as tasks inside of the main `distro-seed` tree.
[^3]: Paths for these are processed in the order they are listed in the defconfig.
