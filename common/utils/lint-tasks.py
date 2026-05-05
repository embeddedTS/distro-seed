#!/usr/bin/env python3

import os
import re
import stat
import sys

import yaml

VALID_CMD_TYPES = {
    "host",
    "vm",
    "cross",
    "target",
    "dummy",
    "packagelist",
    "packagelist-cross",
}

VM_RELATIVE_HELPER = re.compile(r"(^|[^/])common/(host|vm)/")
KCONFIG_SYMBOL = re.compile(r"^\s*(?:config|menuconfig)\s+([A-Z0-9_]+)\b", re.MULTILINE)


def load_kconfig_symbols():
    symbols = set()
    for root, _, files in os.walk("."):
        if root.startswith("./work") or root.startswith("./dl") or root.startswith("./cache"):
            continue
        for filename in files:
            if filename != "Kconfig":
                continue
            path = os.path.join(root, filename)
            with open(path, encoding="utf-8") as kconfig:
                symbols.update(KCONFIG_SYMBOL.findall(kconfig.read()))
    return symbols


def manifest_paths():
    paths = []
    for root, _, files in os.walk("tasks"):
        if "manifest.yaml" in files:
            paths.append(os.path.join(root, "manifest.yaml"))
    return sorted(paths)


def is_executable(path):
    return os.path.exists(path) and os.stat(path).st_mode & stat.S_IXUSR


def lint_manifest(path, kconfig_symbols):
    errors = []
    task_dir = os.path.dirname(path)
    is_overlay = ":" in task_dir

    if is_overlay:
        base_dir = task_dir.split(":", 1)[0]
        if not os.path.isdir(base_dir):
            errors.append(f"{path}: overlay base directory {base_dir} does not exist")
        if not os.path.exists(os.path.join(base_dir, "manifest.yaml")):
            errors.append(f"{path}: overlay base manifest {base_dir}/manifest.yaml does not exist")

    try:
        with open(path, encoding="utf-8") as manifest_file:
            manifest = yaml.safe_load(manifest_file)
    except Exception as exc:
        return [f"{path}: failed to parse YAML: {exc}"]

    if not isinstance(manifest, dict):
        return [f"{path}: manifest must be a mapping"]

    config = manifest.get("config")
    if not config:
        errors.append(f"{path}: missing config")
    elif config not in kconfig_symbols:
        errors.append(f"{path}: config {config} is not defined by Kconfig")

    tasks = manifest.get("tasks")
    if not isinstance(tasks, list) or not tasks:
        errors.append(f"{path}: tasks must be a non-empty list")
        return errors

    for idx, task in enumerate(tasks, start=1):
        if not isinstance(task, dict):
            errors.append(f"{path}: task {idx} must be a mapping")
            continue

        cmd_type = task.get("cmd_type")
        if cmd_type not in VALID_CMD_TYPES:
            errors.append(f"{path}: task {idx} has invalid cmd_type {cmd_type!r}")

        cmd = task.get("cmd", "")
        if cmd_type != "dummy":
            if not cmd:
                errors.append(f"{path}: task {idx} missing cmd")
                continue
            cmd_path = os.path.normpath(os.path.join(task_dir, cmd))
            if not os.path.exists(cmd_path):
                errors.append(f"{path}: task {idx} cmd {cmd} does not exist")
                continue
            if not is_executable(cmd_path):
                errors.append(f"{path}: task {idx} cmd {cmd} is not executable")

            if cmd_type == "vm":
                with open(cmd_path, "rb") as script:
                    text = script.read().decode("utf-8", errors="ignore")
                if VM_RELATIVE_HELPER.search(text):
                    errors.append(
                        f"{path}: task {idx} vm cmd {cmd} uses relative common/... helper path; use /src/common/..."
                    )

        dependencies = task.get("dependencies", [])
        if dependencies is not None and not isinstance(dependencies, list):
            errors.append(f"{path}: task {idx} dependencies must be a list")

    return errors


def main():
    os.chdir(os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__)))))
    kconfig_symbols = load_kconfig_symbols()
    errors = []
    for path in manifest_paths():
        errors.extend(lint_manifest(path, kconfig_symbols))

    if errors:
        for error in errors:
            print(f"Fail: {error}", file=sys.stderr)
        return 1

    print("Pass: task manifests and scripts look consistent.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
