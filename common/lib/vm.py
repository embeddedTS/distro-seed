#!/usr/bin/env python3

import base64
import os
import selectors
import shutil
import signal
import socket
import subprocess
import sys
import termios
import time
import tty
import uuid


VM_PYTHON_VENV = "/opt/distro-seed/venv"

# Startup waits for a newly-launched VM to boot and report ready. Shutdown
# waits for graceful guest poweroff before forcing qemu down.
VM_STARTUP_TIMEOUT_SEC = 15 * 60  # Typically ~11 seconds
VM_SHUTDOWN_TIMEOUT_SEC = 5 * 60  # Typically ~5 seconds

# Runtime control operations are quick protocol exchanges with the serial agent.
VM_CONTROL_TIMEOUT_SEC = 60  # Typically < 2s


class VMError(RuntimeError):
    pass


def _env_path(name):
    value = os.environ.get(name)
    if not value:
        raise VMError(f"{name} is not set")
    return value


def vm_dir():
    return os.path.join(_env_path("DS_WORK"), "qemu-host")


def _append_console_log(chunk):
    os.makedirs(vm_dir(), exist_ok=True)
    with open(os.path.join(vm_dir(), "console.log"), "ab") as log:
        log.write(chunk)


def _strip_protocol_lines(chunk):
    lines = chunk.splitlines(keepends=True)
    kept = []
    for line in lines:
        stripped = line.rstrip(b"\r\n")
        if stripped.startswith(b"__DS_BEGIN__ ") or stripped.startswith(b"__DS_END__ "):
            continue
        kept.append(line)
    return b"".join(kept)


def _pid_alive(pid):
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def _read_pid(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return int(f.read().strip())
    except (FileNotFoundError, ValueError):
        return None


def _remaining_timeout(deadline):
    return max(0.0, deadline - time.time())


def _print_timeout_exceeded(name, timeout, start):
    elapsed = time.time() - start
    print(
        f"{name}: timeout={timeout:.3f}s exceeded after {elapsed:.3f}s",
        file=sys.stderr,
        flush=True,
    )


def cleanup_abandoned_vm():
    qdir = vm_dir()
    ds_pid_file = os.path.join(qdir, "distro-seed.pid")
    qemu_pid_file = os.path.join(qdir, "qemu.pid")
    ds_pid = _read_pid(ds_pid_file)
    qemu_pid = _read_pid(qemu_pid_file)

    if qemu_pid is None:
        return

    if ds_pid == os.getpid() and _pid_alive(qemu_pid):
        return

    if ds_pid is not None and _pid_alive(ds_pid) and _pid_alive(qemu_pid):
        return

    _kill_qemu(qemu_pid)

    for path in (qemu_pid_file, ds_pid_file, os.path.join(qdir, "control.sock")):
        try:
            os.unlink(path)
        except FileNotFoundError:
            pass


def _kill_qemu(qemu_pid):
    if _pid_alive(qemu_pid):
        os.kill(qemu_pid, signal.SIGTERM)
    for _ in range(50):
        if not _pid_alive(qemu_pid):
            break
        time.sleep(0.1)
    if _pid_alive(qemu_pid):
        os.kill(qemu_pid, signal.SIGKILL)


def _require_kvm():
    if os.uname().machine != "x86_64":
        raise VMError("The distro-seed VM requires an x86_64 host")
    if not os.path.exists("/dev/kvm") or not os.access("/dev/kvm", os.R_OK | os.W_OK):
        raise VMError("KVM is required, but /dev/kvm is not available to this user")
    if shutil.which("qemu-system-x86_64") is None:
        raise VMError("qemu-system-x86_64 is required")
    if shutil.which("qemu-img") is None:
        raise VMError("qemu-img is required")


def _runtime_image():
    qdir = vm_dir()
    base = os.path.join(qdir, "base.qcow2")
    runtime = os.path.join(qdir, "runtime.qcow2")
    if not os.path.exists(base):
        raise VMError(f"VM base image is missing: {base}")
    if not os.path.exists(runtime):
        subprocess.run(
            [
                "qemu-img",
                "create",
                "-f",
                "qcow2",
                "-F",
                "qcow2",
                "-b",
                base,
                runtime,
            ],
            check=True,
        )
    return runtime


def _vm_work_image():
    image = os.path.join(vm_dir(), "vm-work.qcow2")
    if not os.path.exists(image):
        subprocess.run(
            [
                "qemu-img",
                "create",
                "-f",
                "qcow2",
                image,
                "64G",
            ],
            check=True,
        )
    return image


def is_running():
    qemu_pid = _read_pid(os.path.join(vm_dir(), "qemu.pid"))
    if qemu_pid is None or not _pid_alive(qemu_pid):
        return False
    return True


def ensure_vm_image():
    if is_running():
        return
    subprocess.run("tasks/core/build_vm/build_vm.sh", check=True)


def _host_ram_gb():
    pages = os.sysconf("SC_PHYS_PAGES")
    page_size = os.sysconf("SC_PAGE_SIZE")
    return (pages * page_size) // (1000 ** 3)


def _vm_resources():
    env_cores = os.environ.get("DS_VM_CORES")
    env_ram = os.environ.get("DS_VM_RAM")
    if env_cores or env_ram:
        return env_cores or str(min(os.cpu_count() or 1, 8)), env_ram or "6G"

    # RAM tiers: <32 GB uses up to 16 cores/6G, 32 GB uses up to 24 cores/16G,
    # and 64 GB or larger uses up to 32 cores/32G.
    host_cores = os.cpu_count() or 1
    host_ram_gb = _host_ram_gb()
    if host_ram_gb >= 64:
        return str(min(host_cores, 32)), "32G"
    if host_ram_gb >= 32:
        return str(min(host_cores, 24)), "16G"
    return str(min(host_cores, 16)), "6G"


def start_vm():
    qdir = vm_dir()
    os.makedirs(qdir, exist_ok=True)
    cleanup_abandoned_vm()

    qemu_pid_file = os.path.join(qdir, "qemu.pid")
    boot_log = os.path.join(qdir, "boot.log")
    qemu_pid = _read_pid(qemu_pid_file)
    if qemu_pid is not None and _pid_alive(qemu_pid):
        return

    _require_kvm()

    control_sock = os.path.join(qdir, "control.sock")
    try:
        os.unlink(control_sock)
    except FileNotFoundError:
        pass

    session_pid = os.environ.get("DS_SESSION_PID", str(os.getpid()))
    with open(os.path.join(qdir, "distro-seed.pid"), "w", encoding="utf-8") as f:
        f.write(f"{session_pid}\n")

    smp, memory = _vm_resources()
    cmd = [
        "qemu-system-x86_64",
        "-enable-kvm",
        "-machine",
        "q35,accel=kvm",
        "-cpu",
        "host",
        "-smp",
        smp,
        "-m",
        memory,
        "-display",
        "none",
        "-no-reboot",
        "-daemonize",
        "-pidfile",
        qemu_pid_file,
        "-drive",
        f"if=none,id=rootdisk,file={_runtime_image()},format=qcow2",
        "-device",
        "virtio-blk-pci,drive=rootdisk,serial=ds-root,bootindex=1",
        "-drive",
        f"if=none,id=vmwork,file={_vm_work_image()},format=qcow2",
        "-device",
        "virtio-blk-pci,drive=vmwork,serial=ds-vm-work,bootindex=2",
        "-netdev",
        "user,id=net0",
        "-device",
        "virtio-net-pci,netdev=net0",
        "-device",
        "virtio-rng-pci",
        "-device",
        "virtio-serial-pci",
        "-chardev",
        f"socket,id=dscontrol,path={control_sock},server=on,wait=off",
        "-device",
        "virtserialport,chardev=dscontrol,name=ds-control",
        "-serial",
        f"file:{boot_log}",
        "-fsdev",
        f"local,id=cache,path={_env_path('DS_CACHE')},security_model=mapped-xattr",
        "-device",
        "virtio-9p-pci,fsdev=cache,mount_tag=cache",
        "-fsdev",
        f"local,id=dl,path={_env_path('DS_DL')},security_model=mapped-xattr",
        "-device",
        "virtio-9p-pci,fsdev=dl,mount_tag=dl",
        "-fsdev",
        f"local,id=work,path={_env_path('DS_WORK')},security_model=mapped-xattr",
        "-device",
        "virtio-9p-pci,fsdev=work,mount_tag=work",
        "-fsdev",
        f"local,id=src,path={_env_path('DS_HOST_ROOT_PATH')},security_model=none,readonly=on",
        "-device",
        "virtio-9p-pci,fsdev=src,mount_tag=src",
    ]
    subprocess.run(cmd, check=True)
    wait_ready()


def stop_vm():
    qdir = vm_dir()
    start = time.time()
    deadline = time.time() + VM_SHUTDOWN_TIMEOUT_SEC
    qemu_pid = _read_pid(os.path.join(qdir, "qemu.pid"))
    if qemu_pid is not None and _pid_alive(qemu_pid):
        s = None
        try:
            s = _connect(min(VM_CONTROL_TIMEOUT_SEC, _remaining_timeout(deadline)))
            s.sendall(b"PING\n")
            _read_until(
                s,
                [b"READY\n"],
                timeout=min(VM_CONTROL_TIMEOUT_SEC, _remaining_timeout(deadline)),
                log=False,
            )
            s.sendall(b"POWEROFF\n")
            _read_until(
                s,
                [b"BYE\n"],
                timeout=min(VM_CONTROL_TIMEOUT_SEC, _remaining_timeout(deadline)),
                log=False,
            )
        except (OSError, VMError):
            pass
        finally:
            if s is not None:
                s.close()
    qemu_pid = _read_pid(os.path.join(qdir, "qemu.pid"))
    if qemu_pid is not None:
        while time.time() < deadline:
            if not _pid_alive(qemu_pid):
                break
            time.sleep(0.1)
        if _pid_alive(qemu_pid):
            _print_timeout_exceeded(
                "VM_SHUTDOWN_TIMEOUT_SEC",
                VM_SHUTDOWN_TIMEOUT_SEC,
                start,
            )
            _kill_qemu(qemu_pid)
    for path in ("qemu.pid", "distro-seed.pid", "control.sock"):
        try:
            os.unlink(os.path.join(qdir, path))
        except FileNotFoundError:
            pass


def _connect(timeout=VM_CONTROL_TIMEOUT_SEC, timeout_name="VM_CONTROL_TIMEOUT_SEC"):
    start = time.time()
    sock_path = os.path.join(vm_dir(), "control.sock")
    deadline = time.time() + timeout
    last_error = None
    while time.time() < deadline:
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(sock_path)
            s.setblocking(False)
            return s
        except OSError as exc:
            last_error = exc
            time.sleep(0.25)
    if timeout_name:
        _print_timeout_exceeded(timeout_name, timeout, start)
    raise VMError(f"Timed out connecting to VM control socket: {last_error}")


def wait_ready():
    start = time.time()
    deadline = time.time() + VM_STARTUP_TIMEOUT_SEC
    s = None
    try:
        s = _connect(_remaining_timeout(deadline), timeout_name=None)
        s.sendall(b"PING\n")
        output, _ = _read_until(
            s,
            [b"READY\n"],
            timeout=_remaining_timeout(deadline),
            timeout_name=None,
            log=False,
        )
        if b"READY" not in output:
            raise VMError("VM serial agent did not become ready")
    except Exception:
        if time.time() >= deadline:
            _print_timeout_exceeded(
                "VM_STARTUP_TIMEOUT_SEC",
                VM_STARTUP_TIMEOUT_SEC,
                start,
            )
        raise
    finally:
        if s is not None:
            s.close()


def _read_until(
    sock,
    markers,
    timeout=VM_CONTROL_TIMEOUT_SEC,
    timeout_name="VM_CONTROL_TIMEOUT_SEC",
    log=True,
):
    start = time.time()
    selector = selectors.DefaultSelector()
    selector.register(sock, selectors.EVENT_READ)
    data = bytearray()
    deadline = None if timeout is None else time.time() + timeout
    while True:
        if deadline is None:
            select_timeout = None
        else:
            select_timeout = deadline - time.time()
            if select_timeout <= 0:
                break
        events = selector.select(select_timeout)
        for key, _ in events:
            chunk = key.fileobj.recv(65536)
            if not chunk:
                raise VMError("VM control socket closed")
            if log:
                _append_console_log(_strip_protocol_lines(chunk))
            data.extend(chunk)
            for marker in markers:
                if marker in data:
                    return bytes(data), marker
    if timeout_name:
        _print_timeout_exceeded(timeout_name, timeout, start)
    raise VMError(f"Timed out after {timeout}s without VM serial output")


def _env_exports(env):
    lines = []
    for key, value in sorted(env.items()):
        escaped = value.replace("'", "'\"'\"'")
        lines.append(f"export {key}='{escaped}'")
    return "\n".join(lines)


def vm_env(extra=None):
    env = {
        "DS_HOST_ROOT_PATH": "/src",
        "DS_CACHE": "/cache",
        "DS_DL": "/dl",
        "DS_PYTHON_VENV": VM_PYTHON_VENV,
        "DS_WORK": "/work",
        "DS_TARGET_ROOTFS": "/vm-work/rootfs",
    }
    for key, value in os.environ.items():
        if key.startswith("CONFIG_") or key.startswith("DS_"):
            env[key] = value
    env.update(
        {
            "DS_HOST_ROOT_PATH": "/src",
            "DS_CACHE": "/cache",
            "DS_DL": "/dl",
            "DS_PYTHON_VENV": VM_PYTHON_VENV,
            "DS_WORK": "/work",
            "DS_TARGET_ROOTFS": "/vm-work/rootfs",
        }
    )
    if extra:
        env.update(extra)
    return env


def run_script(name, script, env=None, timeout=None):
    start_vm()
    return _run_script(name, script, env=env, timeout=timeout)


def _run_agent_script(name, script, env=None, timeout=None):
    token = f"{name}-{uuid.uuid4().hex[:12]}"
    payload = (_env_exports(vm_env(env)) + "\n" + script).encode("utf-8")
    encoded = base64.b64encode(payload).decode("ascii")

    s = _connect()
    try:
        _send_payload(s, token, encoded)
        output, _ = _read_until(
            s,
            [f"__DS_END__ {token} ".encode("ascii")],
            timeout=timeout,
            timeout_name=None,
        )
    finally:
        s.close()

    end_line = ""
    text = output.decode("utf-8", errors="replace")
    for line in text.splitlines():
        if line.startswith(f"__DS_END__ {token} "):
            end_line = line
    if not end_line:
        raise VMError("VM command ended without a status marker")
    return int(end_line.rsplit(" ", 1)[1]), _strip_protocol_lines(output)


def _run_script(name, script, env=None, timeout=None):
    status, output = _run_agent_script(name, script, env=env, timeout=timeout)
    print(output.decode("utf-8", errors="replace"), end="")
    if status != 0:
        raise subprocess.CalledProcessError(status, name)


def _send_payload(sock, token, encoded, ready_timeout=VM_CONTROL_TIMEOUT_SEC):
    sock.sendall(b"PING\n")
    _read_until(sock, [b"READY\n"], timeout=ready_timeout, log=False)
    sock.sendall(f"RUNB64_BEGIN {token}\n".encode("ascii"))
    for idx in range(0, len(encoded), 60000):
        sock.sendall(f"RUNB64_DATA {token} {encoded[idx:idx + 60000]}\n".encode("ascii"))
    sock.sendall(f"RUNB64_END {token}\n".encode("ascii"))


def _interactive_script(name, script, env=None):
    start_vm()
    token = f"{name}-{uuid.uuid4().hex[:12]}"
    payload = (_env_exports(vm_env(env)) + "\n" + script).encode("utf-8")
    encoded = base64.b64encode(payload).decode("ascii")

    s = _connect()
    old_termios = None
    try:
        _send_payload(s, token, encoded)
        if sys.stdin.isatty():
            old_termios = termios.tcgetattr(sys.stdin.fileno())
            tty.setraw(sys.stdin.fileno())
            raw_termios = termios.tcgetattr(sys.stdin.fileno())
            raw_termios[1] = old_termios[1]
            termios.tcsetattr(sys.stdin.fileno(), termios.TCSADRAIN, raw_termios)
        s.setblocking(False)
        while True:
            readers = [s, sys.stdin]
            readable, _, _ = select_compat(readers)
            if s in readable:
                chunk = s.recv(65536)
                if not chunk:
                    break
                visible = _strip_protocol_lines(chunk)
                _append_console_log(visible)
                os.write(sys.stdout.fileno(), visible)
                if f"__DS_END__ {token} ".encode("ascii") in chunk:
                    break
            if sys.stdin in readable:
                data = os.read(sys.stdin.fileno(), 4096)
                if not data:
                    break
                s.sendall(data)
    finally:
        if old_termios is not None:
            termios.tcsetattr(sys.stdin.fileno(), termios.TCSADRAIN, old_termios)
        s.close()


def select_compat(readers):
    import select

    return select.select(readers, [], [])


def _vm_pty_command(command):
    escaped = command.replace("'", "'\"'\"'")
    return f"exec script -qfec '{escaped}' /dev/null"


def interactive_shell(kind):
    if kind == "vm":
        script = _vm_pty_command("/bin/bash -il")
    elif kind == "cross":
        script = "/src/tasks/core/cross_ready/setup-cross.sh\n" + _vm_pty_command(
            "/usr/sbin/chroot /tmp/distro-seed-cross /bin/bash -il"
        )
    elif kind == "target":
        script = "/src/common/vm/mount-target.sh\n" + _vm_pty_command(
            "/usr/sbin/chroot ${DS_TARGET_ROOTFS:-/vm-work/rootfs} /bin/bash -il"
        )
    else:
        raise VMError(f"Unknown shell kind {kind}")
    _interactive_script(f"{kind}-shell", script)
