#!/usr/bin/env python3

import argparse
import json
import os
import selectors
import socket
import subprocess
import sys
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--idle-timeout", type=float, default=180.0)
    parser.add_argument("--log", required=True)
    parser.add_argument("--quiet", action="store_true", help="Write command output only to the log file")
    parser.add_argument("--qmp-socket", help="Treat a QMP SHUTDOWN event as successful completion")
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()

    command = args.command
    if command and command[0] == "--":
        command = command[1:]
    if not command:
        parser.error("missing command")

    os.makedirs(os.path.dirname(os.path.abspath(args.log)), exist_ok=True)
    proc = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        bufsize=0,
    )

    selector = selectors.DefaultSelector()
    selector.register(proc.stdout, selectors.EVENT_READ)
    qmp = None
    qmp_buffer = b""
    last_output = time.monotonic()

    with open(args.log, "ab") as log:
        while proc.poll() is None:
            if args.qmp_socket and qmp is None and os.path.exists(args.qmp_socket):
                try:
                    qmp = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                    qmp.connect(args.qmp_socket)
                    qmp.setblocking(False)
                    selector.register(qmp, selectors.EVENT_READ)
                    qmp.sendall(b'{"execute":"qmp_capabilities"}\r\n')
                except OSError:
                    if qmp is not None:
                        qmp.close()
                    qmp = None

            remaining = args.idle_timeout - (time.monotonic() - last_output)
            if remaining <= 0:
                proc.terminate()
                try:
                    proc.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait()
                print(
                    f"\nCommand timed out after {args.idle_timeout:.0f}s without output",
                    file=sys.stderr,
                )
                return 124

            events = selector.select(min(1.0, remaining))
            for key, _ in events:
                if qmp is not None and key.fileobj == qmp:
                    chunk = qmp.recv(65536)
                    if not chunk:
                        selector.unregister(qmp)
                        qmp.close()
                        qmp = None
                        continue
                    qmp_buffer += chunk
                    while b"\n" in qmp_buffer:
                        line, qmp_buffer = qmp_buffer.split(b"\n", 1)
                        line = line.strip()
                        if not line:
                            continue
                        try:
                            message = json.loads(line.decode("utf-8"))
                        except json.JSONDecodeError:
                            continue
                        if message.get("event") == "SHUTDOWN":
                            try:
                                qmp.sendall(b'{"execute":"quit"}\r\n')
                            except OSError:
                                proc.terminate()
                            try:
                                proc.wait(timeout=10)
                            except subprocess.TimeoutExpired:
                                proc.kill()
                                proc.wait()
                            return 0
                    continue

                chunk = os.read(key.fileobj.fileno(), 65536)
                if not chunk:
                    continue
                last_output = time.monotonic()
                if not args.quiet:
                    os.write(sys.stdout.fileno(), chunk)
                log.write(chunk)
                log.flush()

        leftover = proc.stdout.read() if proc.stdout else b""
        if leftover:
            if not args.quiet:
                os.write(sys.stdout.fileno(), leftover)
            log.write(leftover)

    if proc.returncode is not None and proc.returncode < 0:
        return 128 + abs(proc.returncode)
    return proc.returncode or 0


if __name__ == "__main__":
    sys.exit(main())
