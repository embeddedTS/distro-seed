"""Discovery and path mapping for one additive external tree."""
import glob
import os


def root():
    value = os.environ.get("DS_EXTERNAL", "")
    return os.path.realpath(value) if value else ""


def contains(path):
    base = root()
    path = os.path.realpath(path)
    source = os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))
    if base and os.path.commonpath([base, source]) == base:
        if os.path.commonpath([source, path]) == source:
            return False
    return bool(base) and os.path.commonpath([base, path]) == base


def guest_path(path):
    if contains(path):
        return "/external/" + os.path.relpath(path, root())
    return "/src/" + os.path.relpath(path, os.environ["DS_HOST_ROOT_PATH"])


def validate_symbols(kconf):
    if not root():
        return
    if not os.path.isfile(os.path.join(root(), "Kconfig")):
        raise ValueError("DS_EXTERNAL must contain Kconfig")
    for symbol in kconf.unique_defined_syms:
        origins = {contains(node.filename) for node in symbol.nodes}
        if origins == {True, False}:
            raise ValueError(f"External Kconfig redefines built-in symbol {symbol.name}")


def load_tasks(kconf, manager):
    validate_symbols(kconf)
    tasks = []
    reserved = set()
    for directory in ["tasks"] + ([os.path.join(root(), "tasks")] if root() else []):
        external_tree = os.path.isabs(directory)
        for manifest in sorted(glob.glob(os.path.join(directory, "**", "manifest.yaml"), recursive=True)):
            if ":" in os.path.relpath(manifest, directory):
                if external_tree:
                    raise ValueError("External task overlays are not supported: " + manifest)
                continue
            loaded = manager.load_tasks_from_manifest(manifest)
            names = {t.config for t in loaded} | {t.provides for t in loaded if t.provides}
            if external_tree:
                if names & reserved:
                    raise ValueError("External task collides with existing task: " + str(names & reserved))
                for task in loaded:
                    symbol = kconf.syms.get(task.config)
                    if not symbol or not symbol.nodes or not all(contains(n.filename) for n in symbol.nodes):
                        raise ValueError("External task must use its own Kconfig symbol: " + task.config)
            reserved.update(names)
            tasks.extend(loaded)
    return tasks
