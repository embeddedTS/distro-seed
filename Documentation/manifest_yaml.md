The manifest.yaml specifies any tasks necessary to build an object. For example, this is an example software package yaml:

```
config: DS_COMPONENT_TSSUPERVISORUPDATE
tasks:
- cmd_type: host
  cmd: fetch.sh
  description: Downloading tssupervisorupdate
- cmd_type: cross
  cmd: build.sh
  description: Building tssupervisorupdate
```

# config
This option must match an option specified in Kconfig. Even if the option is not optional, it must have a Kconfig that enables it such as:
```
config DS_COMPONENT_TSSUPERVISORUPDATE
	bool
        default "y"
```
This would enable the config option without showing up in the menu, but satisy the kconfig symbol.

# tasks
The tasks are a json list of the fields described before.  A single manifest can include any number of tasks, but most are 1-3 at most.

## cmd_type
The cmdtype can be one of these options:

* host
  * Executes the task on the host OS. Most fetch (like git clone, wget) should be run from the host to use any of the system's credentials or network configuration. The host task should not be used to build projects.
* vm
  * These are most commonly shell or python
  * Executes the "cmd" script in the shared Debian 13 QEMU VM. This is used for rootfs assembly, image generation, and other tasks that need Linux filesystem behavior without running directly on the host.
* cross
  * Executes the "cmd" script in a target-matching build chroot inside the QEMU VM. The chroot uses the selected distro/release and includes cross compilers and target-architecture development packages.
  * Most source builds should use `cross`.
* target
  * These tasks are executed in the target rootfs from inside the QEMU VM. The task script specified in cmd is copied into the VM-local rootfs, then chrooted and executed.
  * Whenever possible target's "cmd" should point at a bash script for best compatibility between target distributions.
* dummy
  * These tasks perform nothing, and are only used for dependency synchronization.
* packagelist
  * The packagelist cmd executes on the host, but any stdout is used to select packages to end up in the target debian image.  For example, a packagelist cmd script that runs ```echo figlet``` would add the figlet package to the image.
* packagelist-cross
  * The packagelist-cross cmd executes on the host, but stdout is used to select packages installed into the cross chroot. Use this when a build task needs extra tools or target development packages.

For `host`, `vm`, and `cross` tasks, target filesystem content should be written
to `DS_OVERLAY`. If that directory is non-empty when the task exits, distro-seed
stores it as a tar artifact, builds it into a generated local Debian package,
and installs that package into the target rootfs later in task order. Optional
Debian maintainer scripts and a package version can be written under
`DS_OVERLAY_CONTROL`.

Supported `DS_OVERLAY_CONTROL` files are `preinst`, `postinst`, `prerm`,
`postrm`, and `version`. Maintainer scripts are installed into the generated
package as executable files. Host, VM, and cross tasks run with umask `022`.
Package payload ownership defaults to `root:root`; use maintainer scripts for
intentional non-root ownership.

## cmd
The cmd field is the name of the script to run. In general, this should point to a shell script, or python if it is a task run on the host.

## dependencies
This is a list of 'config' or 'provides' tasks that will be completed before this task. When not specified the 'dependencies' will be set to sane defaults based on the cmd_type to execute as soon as possible, and complete before moving onto the next stage of the image generation. Otherwise, dependencies looks for valid "config" tasks to execute before this task.

To show the dependencies, set up your .config and run:
```
make plotdeps
```
which will show a grahical representation of any dependencies.

## provides
This can be used to specify a name that can be used in dependencies. This is either used to allow multiple 'config' options to provide the same feature, or it can be used to create a dependency on an individual task rather than a config (which can contain multiple tasks)

## description
The description prints out during execution of a build to show the current task.

## auto_create_rdepends
This is used by core tasks to automatically create reverse dependencies to the children of its parent tasks that do not have children of their own. This makes sure all previous tasks are completed before proceeding.

To show the reverse dependencies, set up your .config and run:
```
make plotdeps
```
which will show a grahical representation of any dependencies. The tasks with green dotted lines are the tasks that are automatically added as reverse dependencies.
