"""
task.py - Module for defining and executing distro-seed tasks.

This module provides a Task class that represents a distro-seed task, which involves
the distribution and seeding of resources or data across a system or network. The
Task class provides a basic structure to define and execute such tasks.

Usage:
    # Import the Task class
    from task import Task
    from task_manager import Task

    prep_tasks = task_manager.load_tasks_from_manifest('tasks/core/chroot_prep/manifest.yaml')
    for prep in prep_tasks:
        prep.run()
"""

import os
import subprocess
import shutil
import tempfile

from lib import vm

class Task:
    """Setup task to execute in different environments """

    def __init__(self, config, path, task_manifest):
        self.config = config
        self.dependencies = task_manifest.dependencies
        self.provides = task_manifest.provides
        self.path = path
        self.cmd_type = task_manifest.cmd_type
        self.cmd = task_manifest.cmd
        self.description = task_manifest.description
        self.auto_create_rdepends = task_manifest.auto_create_rdepends
        self.id = 0

    def _package_input_name(self):
        return f"{self.id}-{self.config}"

    def _package_input_dir(self, work):
        return os.path.abspath(os.path.join(work, "package-inputs", self._package_input_name()))

    def _has_entries(self, path):
        if not os.path.isdir(path):
            return False
        with os.scandir(path) as entries:
            return any(entries)

    def _stage_host_package_input(self, work, overlay, control):
        if not self._has_entries(overlay) and not self._has_entries(control):
            return

        package_input = self._package_input_dir(work)
        if os.path.exists(package_input):
            shutil.rmtree(package_input)

        os.makedirs(package_input, exist_ok=True)

        if self._has_entries(overlay):
            subprocess.run(
                [
                    "tar",
                    "--xattrs",
                    "--xattrs-include=*",
                    "--acls",
                    "--selinux",
                    "--numeric-owner",
                    "--sparse",
                    "-cpf",
                    os.path.join(package_input, "data.tar"),
                    ".",
                ],
                cwd=overlay,
                check=True,
            )
        if self._has_entries(control):
            subprocess.run(
                [
                    "tar",
                    "--xattrs",
                    "--xattrs-include=*",
                    "--acls",
                    "--selinux",
                    "--numeric-owner",
                    "--sparse",
                    "-cpf",
                    os.path.join(package_input, "control.tar"),
                    ".",
                ],
                cwd=control,
                check=True,
            )

    def run(self):
        """ Execute task in target environment """

        # These are placeholders only used for dependency tracking
        if self.cmd_type == 'dummy':
            return
    
        ds_host_root_path = os.environ.get('DS_HOST_ROOT_PATH')
        work = os.environ.get('DS_WORK')
        full_cmd = os.path.relpath(
                f"{self.path}/{self.cmd}", ds_host_root_path)
        os.environ['DS_TASK_PATH'] = os.path.abspath(os.environ['DS_HOST_ROOT_PATH'] + '/' + self.path)
        
        if not os.path.isfile(full_cmd):
            raise ValueError(f'{self.config} has task \"{full_cmd}\" that does not exist')

        if self.cmd_type == 'host':
            # Execute in our current environment. This is mostly used for
            # fetches and early setup commands.
            taskenv = os.environ.copy()
            tmp_parent = os.path.abspath(os.path.join(work, "tmp"))
            os.makedirs(tmp_parent, exist_ok=True)
            overlay_tmp = tempfile.mkdtemp(prefix="ds-overlay.", dir=tmp_parent)
            control_tmp = tempfile.mkdtemp(prefix="ds-overlay-control.", dir=tmp_parent)
            package_input = self._package_input_dir(work)
            if os.path.exists(package_input):
                shutil.rmtree(package_input)
            taskenv['DS_OVERLAY'] = overlay_tmp
            taskenv['DS_OVERLAY_CONTROL'] = control_tmp
            try:
                subprocess.run(
                    full_cmd,
                    check=True,
                    env=taskenv,
                    preexec_fn=lambda: os.umask(0o022)
                )
                self._stage_host_package_input(work, overlay_tmp, control_tmp)
            finally:
                shutil.rmtree(overlay_tmp, ignore_errors=True)
                shutil.rmtree(control_tmp, ignore_errors=True)
        elif self.cmd_type == "packagelist":
            packagelist_file = os.path.abspath(work + f'/packagelist/{self.id}-{self.config}')
            packagelist_dir = os.path.dirname(packagelist_file)

            os.makedirs(packagelist_dir, exist_ok=True)
            taskenv = os.environ.copy()

            with open(packagelist_file, 'w', encoding='utf-8') as packagelist:
                subprocess.run(full_cmd, check=True, env=taskenv, stdout=packagelist)
        elif self.cmd_type == "packagelist-cross":
            packagelist_file = os.path.abspath(work + f'/packagelist-cross/{self.id}-{self.config}')
            packagelist_dir = os.path.dirname(packagelist_file)

            os.makedirs(packagelist_dir, exist_ok=True)
            taskenv = os.environ.copy()

            with open(packagelist_file, 'w', encoding='utf-8') as packagelist:
                subprocess.run(full_cmd, check=True, env=taskenv, stdout=packagelist)
        elif self.cmd_type == "vm":
            vm_cmd = f"/src/{full_cmd}"
            package_input_name = self._package_input_name()
            script = f"""
set -e
umask 022
overlay_tmp="$(mktemp -d /tmp/ds-overlay.XXXXXX)"
control_tmp="$(mktemp -d /tmp/ds-overlay-control.XXXXXX)"
package_input="/work/package-inputs/{package_input_name}"
rm -rf "$package_input"
export DS_OVERLAY="$overlay_tmp"
export DS_OVERLAY_CONTROL="$control_tmp"
export DS_TASK_PATH="/src/{self.path}"
"{vm_cmd}"
if [[ -n "$(find "$overlay_tmp" "$control_tmp" -mindepth 1 -print -quit)" ]]; then
    install -d "$package_input"
    if [[ -n "$(find "$overlay_tmp" -mindepth 1 -print -quit)" ]]; then
        tar --xattrs --xattrs-include='*' --acls --selinux --numeric-owner --sparse \
            -C "$overlay_tmp" -cpf "$package_input/data.tar" .
    fi
    if [[ -n "$(find "$control_tmp" -mindepth 1 -print -quit)" ]]; then
        tar --xattrs --xattrs-include='*' --acls --selinux --numeric-owner --sparse \
            -C "$control_tmp" -cpf "$package_input/control.tar" .
    fi
fi
rm -rf "$overlay_tmp"
rm -rf "$control_tmp"
"""
            vm.run_script(self.config, script)
        elif self.cmd_type == "cross":
            cross_cmd = f"/src/{full_cmd}"
            package_input_name = self._package_input_name()
            script = f"""
set -e
umask 022
/src/common/vm/ensure-cross.sh
CROSS_ROOT=/tmp/distro-seed-cross
for dir in cache dl work src vm-work; do
    mkdir -p "$CROSS_ROOT/$dir"
    mountpoint -q "$CROSS_ROOT/$dir" || mount --bind "/$dir" "$CROSS_ROOT/$dir"
done
overlay_tmp="/tmp/ds-overlay-{package_input_name}"
control_tmp="/tmp/ds-overlay-control-{package_input_name}"
package_input="/work/package-inputs/{package_input_name}"
rm -rf "$package_input"
rm -rf "$CROSS_ROOT/$overlay_tmp"
rm -rf "$CROSS_ROOT/$control_tmp"
mkdir -p "$CROSS_ROOT/$overlay_tmp"
mkdir -p "$CROSS_ROOT/$control_tmp"
export DS_OVERLAY="$overlay_tmp"
export DS_OVERLAY_CONTROL="$control_tmp"
export DS_TASK_PATH="/src/{self.path}"
export -p > "$CROSS_ROOT/tmp/ds-env"
cat >> "$CROSS_ROOT/tmp/ds-env" <<'EOS'
source /distro-seed-cross-env
EOS
chroot "$CROSS_ROOT" /bin/bash -lc 'source /tmp/ds-env; cd /src; "{cross_cmd}"'
if [[ -n "$(find "$CROSS_ROOT/$overlay_tmp" "$CROSS_ROOT/$control_tmp" -mindepth 1 -print -quit)" ]]; then
    install -d "$package_input"
    if [[ -n "$(find "$CROSS_ROOT/$overlay_tmp" -mindepth 1 -print -quit)" ]]; then
        tar --xattrs --xattrs-include='*' --acls --selinux --numeric-owner --sparse \
            -C "$CROSS_ROOT/$overlay_tmp" -cpf "$package_input/data.tar" .
    fi
    if [[ -n "$(find "$CROSS_ROOT/$control_tmp" -mindepth 1 -print -quit)" ]]; then
        tar --xattrs --xattrs-include='*' --acls --selinux --numeric-owner --sparse \
            -C "$CROSS_ROOT/$control_tmp" -cpf "$package_input/control.tar" .
    fi
fi
rm -rf "$CROSS_ROOT/$overlay_tmp"
rm -rf "$CROSS_ROOT/$control_tmp"
"""
            vm.run_script(self.config, script)
        elif self.cmd_type == 'target':
            target_cmd = f"/src/{full_cmd}"
            script = f"""
set -e
/src/common/vm/mount-target.sh
cp "{target_cmd}" /work/rootfs/run_in_chroot
export -p > /work/rootfs/tmp/ds-env
chroot /work/rootfs /bin/bash -lc 'source /tmp/ds-env; /run_in_chroot'
rm -f /work/rootfs/run_in_chroot /work/rootfs/tmp/ds-env
"""
            vm.run_script(self.config, script)
        else:
            raise ValueError(f"Invalid cmd_type {self.cmd_type} from {self.config}")
