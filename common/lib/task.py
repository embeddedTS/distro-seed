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
import shlex

from lib import vm

class Task:
    """Setup task to execute in different environments """

    _staging_configs = []
    _staging_provides = {}

    def __init__(self, config, path, task_manifest):
        self.config = config
        self.dependencies = task_manifest.dependencies
        self.provides = task_manifest.provides
        self.path = path
        self.cmd_type = task_manifest.cmd_type
        self.cmd = task_manifest.cmd
        self.description = task_manifest.description
        self.auto_create_rdepends = task_manifest.auto_create_rdepends
        self.manifest_version = task_manifest.manifest_version
        self.pkg_version = task_manifest.pkg_version
        self.id = 0

    @classmethod
    def configure_staging(cls, tasks):
        cls._staging_configs = sorted({task.config for task in tasks})
        cls._staging_provides = {
            task.provides: task.config
            for task in tasks
            if task.provides
        }

    def _package_input_name(self):
        return f"{self.id}-{self.config}"

    def _package_input_dir(self, work):
        return os.path.abspath(os.path.join(work, "package-inputs", self._package_input_name()))

    def _staging_archive_path(self, work):
        return os.path.abspath(os.path.join(work, "staging-archives", f"{self.config}.tar"))

    def _has_entries(self, path):
        if not os.path.isdir(path):
            return False
        with os.scandir(path) as entries:
            return any(entries)

    def _write_package_metadata(self, package_input):
        with open(os.path.join(package_input, "metadata.env"), "w", encoding="utf-8") as metadata:
            metadata.write(f"DS_MANIFEST_VERSION={shlex.quote(self.manifest_version)}\n")
            metadata.write(f"DS_PKG_VERSION={shlex.quote(self.pkg_version)}\n")

    def _staging_env(self, root):
        env = {}
        for config in self._staging_configs:
            env[f"DS_STAGING_{config}"] = os.path.join(root, config)
        for provides, config in self._staging_provides.items():
            env[f"DS_STAGING_{provides}"] = os.path.join(root, config)
        env["DS_STAGING"] = os.path.join(root, self.config)
        return env

    def _task_env(self, base_env, staging_root=None):
        taskenv = base_env.copy()
        taskenv["DS_MANIFEST_VERSION"] = self.manifest_version
        taskenv["DS_PKG_VERSION"] = self.pkg_version
        if staging_root is not None:
            taskenv.update(self._staging_env(staging_root))
        return taskenv

    def _stage_host_package_input(self, work, overlay, debian):
        if not self._has_entries(overlay) and not self._has_entries(debian):
            return

        package_input = self._package_input_dir(work)
        if os.path.exists(package_input):
            shutil.rmtree(package_input)

        os.makedirs(package_input, exist_ok=True)
        self._write_package_metadata(package_input)

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
        if self._has_entries(debian):
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
                    os.path.join(package_input, "debian.tar"),
                    ".",
                ],
                cwd=debian,
                check=True,
            )

    def _stage_host_staging(self, work, staging):
        if not self._has_entries(staging):
            return

        archive = self._staging_archive_path(work)
        os.makedirs(os.path.dirname(archive), exist_ok=True)
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
                archive,
                ".",
            ],
            cwd=staging,
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
            taskenv = self._task_env(taskenv, os.path.abspath(os.path.join(work, "staging")))
            tmp_parent = os.path.abspath(os.path.join(work, "tmp"))
            os.makedirs(tmp_parent, exist_ok=True)
            os.makedirs(taskenv["DS_STAGING"], exist_ok=True)
            overlay_tmp = tempfile.mkdtemp(prefix="ds-overlay.", dir=tmp_parent)
            debian_tmp = tempfile.mkdtemp(prefix="ds-overlay-debian.", dir=tmp_parent)
            package_input = self._package_input_dir(work)
            if os.path.exists(package_input):
                shutil.rmtree(package_input)
            taskenv['DS_OVERLAY'] = overlay_tmp
            taskenv['DS_OVERLAY_PKG_DEBIAN'] = debian_tmp
            try:
                subprocess.run(
                    full_cmd,
                    check=True,
                    env=taskenv,
                    preexec_fn=lambda: os.umask(0o022)
                )
                self._stage_host_package_input(work, overlay_tmp, debian_tmp)
                self._stage_host_staging(work, taskenv["DS_STAGING"])
            finally:
                shutil.rmtree(overlay_tmp, ignore_errors=True)
                shutil.rmtree(debian_tmp, ignore_errors=True)
        elif self.cmd_type == "packagelist":
            packagelist_file = os.path.abspath(work + f'/packagelist/{self.id}-{self.config}')
            packagelist_dir = os.path.dirname(packagelist_file)

            os.makedirs(packagelist_dir, exist_ok=True)
            taskenv = self._task_env(os.environ, os.path.abspath(os.path.join(work, "staging")))
            os.makedirs(taskenv["DS_STAGING"], exist_ok=True)

            with open(packagelist_file, 'w', encoding='utf-8') as packagelist:
                subprocess.run(full_cmd, check=True, env=taskenv, stdout=packagelist)
            self._stage_host_staging(work, taskenv["DS_STAGING"])
        elif self.cmd_type == "packagelist-cross":
            packagelist_file = os.path.abspath(work + f'/packagelist-cross/{self.id}-{self.config}')
            packagelist_dir = os.path.dirname(packagelist_file)

            os.makedirs(packagelist_dir, exist_ok=True)
            taskenv = self._task_env(os.environ, os.path.abspath(os.path.join(work, "staging")))
            os.makedirs(taskenv["DS_STAGING"], exist_ok=True)

            with open(packagelist_file, 'w', encoding='utf-8') as packagelist:
                subprocess.run(full_cmd, check=True, env=taskenv, stdout=packagelist)
            self._stage_host_staging(work, taskenv["DS_STAGING"])
        elif self.cmd_type == "vm":
            taskenv = self._task_env({
                "DS_PACKAGE_INPUT_NAME": self._package_input_name(),
                "DS_TASK_CMD": f"/src/{full_cmd}",
                "DS_TASK_PATH": f"/src/{self.path}",
            }, "/vm-work/staging")
            vm.run_script(self.config, "/src/common/vm/run-vm-task.sh", env=taskenv)
        elif self.cmd_type == "cross":
            taskenv = self._task_env({
                "DS_PACKAGE_INPUT_NAME": self._package_input_name(),
                "DS_TASK_CMD": f"/src/{full_cmd}",
                "DS_TASK_PATH": f"/src/{self.path}",
            }, "/vm-work/staging")
            vm.run_script(self.config, "/src/common/vm/run-cross-task.sh", env=taskenv)
        elif self.cmd_type == 'target':
            taskenv = self._task_env({
                "DS_TASK_CMD": f"/src/{full_cmd}",
            })
            vm.run_script(self.config, "/src/common/vm/run-target-task.sh", env=taskenv)
        else:
            raise ValueError(f"Invalid cmd_type {self.cmd_type} from {self.config}")
