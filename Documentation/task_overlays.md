# Task Overlays

Task overlays let a recipe replace its manifest and scripts for one exact target distribution and release. This keeps distribution-specific behavior out of large shell `if` blocks while keeping the common recipe easy to read.

An overlay directory lives next to the base task directory and is named:

```
<task>:<distro>:<release-number>
```

For example:

```
tasks/components/ts4900-utils/
tasks/components/ts4900-utils:debian:12/
tasks/components/ts4900-utils:ubuntu:24.04/
```

When distro-seed scans manifests, it ignores directories containing `:`. For each base task, it checks whether an exact overlay exists for the selected `DS_DISTRO` and `DS_RELEASE_NUM`. If it exists, distro-seed loads the overlay's `manifest.yaml` instead of the base manifest. If no exact overlay exists, the base manifest is used.

Overlay commands are resolved relative to the overlay directory. They may either use scripts inside the overlay:

```yaml
config: DS_COMPONENT_EXAMPLE
version: "1.2.3"
tasks:
- cmd: fetch.sh
  cmd_type: host
  description: Fetching example for this release
```

or reuse scripts from the base task:

```yaml
config: DS_COMPONENT_EXAMPLE
version: "1.2.3"
tasks:
- cmd: ../example/build.sh
  cmd_type: cross
  description: Building example
```

The overlay manifest is a full replacement, not a patch. If the base task has multiple commands, the overlay should list every command it still needs.

Use overlays when the selected upstream version, package names, build flags, or install behavior really differ by distro/release. Prefer the base task when the same script can reasonably work everywhere.
