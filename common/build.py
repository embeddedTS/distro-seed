#!/usr/bin/env python3

import os
import glob
import sys
import argparse
import atexit
import colorama
import time
from pprint import pprint
from colorama import Fore, Style

from lib.kconfiglib import kconfiglib
from lib.task import Task
from lib import task_manager
from lib.vars import kconfig_export_vars
from lib import vm

colorama.init()

parser = argparse.ArgumentParser()
parser.add_argument("--dry-run", action="store_true", help="Perform a dry run")
parser.add_argument("--plot-deps", action="store_true", help="Graph out dependencies")
args = parser.parse_args()

kconf = kconfiglib.Kconfig('Kconfig')
try:
    kconf.load_config('.config')
except kconfiglib._KconfigIOError as exc:
    sys.stdout.write(str(exc) + "\n")
    print("Did you run make <defconfig>?")
    #sys.exit(2)
kconfig_export_vars(kconf)
os.environ["DS_SESSION_PID"] = str(os.getpid())
atexit.register(vm.stop_vm)

DS_HOST_ROOT_PATH = os.environ['DS_HOST_ROOT_PATH']
DS_DL = os.environ['DS_DL']
DS_WORK = os.environ['DS_WORK']
DS_DISTRO = os.environ['DS_DISTRO']
DS_RELEASE = os.environ['DS_RELEASE']
DS_RELEASE_NUM = os.environ['DS_RELEASE_NUM']
DS_TARGET_ARCH = os.environ['DS_TARGET_ARCH']
DS_QEMU_STATIC = os.environ['DS_QEMU_STATIC']

tasks = []

# Read in all manifests and create tasks for all of them
manifests = [
    manifest
    for manifest in glob.glob(os.path.join('tasks', '**', 'manifest.yaml'), recursive=True)
    if ':' not in os.path.dirname(manifest)
]
for manifest_file in manifests:
    try:
        tasks += task_manager.load_tasks_from_manifest(manifest_file)
    except Exception as e:
        print(f"An error occurred while processing manifest '{manifest_file}': {str(e)}")
        sys.exit(1)

# Remove configs from the list that are not enabled in the config
tasks = [task for task in tasks if kconf.eval_string(task.config) != 0]

# Set default dependencies for each type of task.
for task in tasks:
    # Only set dependencies if there are none
    if len(task.dependencies) != 0:
        continue
    # Every other config will have dependencies except for the work cleanup
    # task, which is sorted first.
    if task.config == 'DS_CORE_CLEAN_WORK':
        continue
    if task.cmd_type == 'host':
        task.dependencies += [ 'DS_WORK_READY' ]
    elif task.cmd_type == 'vm':
        task.dependencies += [ 'DS_VM_READY' ]
    elif task.cmd_type == 'cross':
        task.dependencies += [ 'DS_CROSS_READY' ]
    elif task.cmd_type == 'target':
        task.dependencies += [ 'DS_TARGET_CHROOT_READY' ]
    elif task.cmd_type == 'packagelist':
        task.dependencies += [ 'DS_CORE_PACKAGELIST_PREP' ]
    elif task.cmd_type == 'packagelist-cross':
        task.dependencies += [ 'DS_PACKAGELIST_CROSS_PREP' ]
    else:
        raise ValueError(f"Invalid task type '{task.config.cmd_type}' in '{task.config}'")

# Sort tasks based on their dependencies
try:
    tasks = task_manager.sort(tasks)
except Exception as e:
    print(f"Sort failed: {str(e)}")
    sys.exit(1)

task_manager.write_tasks_mmd(tasks)

if args.plot_deps:
    print("work/tasks.mmd generated")
    sys.exit(0)

# Execute all tasks
timing_records = []
build_start = time.monotonic()
build_status = "pass"

try:
    for i, task in enumerate(tasks, start=1):
        # Print out the description of the command
        print(f"Task: {task.config} ({task.cmd_type}) {i}/{len(tasks)}: {Fore.GREEN}{task.description}{Style.RESET_ALL}")
        start = time.monotonic()
        record = {
            "task": task,
            "start_ms": round((start - build_start) * 1000),
            "end_ms": round((start - build_start) * 1000),
            "status": "running",
        }
        timing_records.append(record)

        try:
            if args.dry_run:
                pprint(f'{task.path}/{task.cmd}')
            else:
                task.run()
            end = time.monotonic()
            record["end_ms"] = round((end - build_start) * 1000)
            record["status"] = "passed"
        except Exception as e:
            end = time.monotonic()
            record["end_ms"] = round((end - build_start) * 1000)
            record["status"] = "failed"
            build_status = "fail"
            print(f"Task failed: {str(e)}")
            sys.exit(1)
finally:
    if timing_records:
        final_time_ms = round((time.monotonic() - build_start) * 1000)
        for record in timing_records:
            if record["status"] == "running":
                record["end_ms"] = final_time_ms
                record["status"] = "failed"
        if any(record["status"] == "failed" for record in timing_records):
            build_status = "fail"
        task_manager.write_task_timing_gantt(timing_records, build_status)
