#!/usr/bin/env python3
"""Print the Hyprland cursor position as `x y` lines, once per interval.

Hyprland has no cursor-move event on its event socket, so the position has to
be polled. One long-lived process asking the request socket is much cheaper
than spawning `hyprctl cursorpos` per sample, and only changed positions are
printed so an idle cursor costs the reader nothing.
"""
import os
import socket
import sys
import time
from pathlib import Path

DEFAULT_INTERVAL_MS = 33


def socket_path() -> Path:
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not signature:
        print("Error: HYPRLAND_INSTANCE_SIGNATURE is not set.", file=sys.stderr)
        sys.exit(1)

    runtime_dir = os.environ.get("XDG_RUNTIME_DIR")
    candidates = []
    if runtime_dir:
        candidates.append(Path(runtime_dir) / "hypr" / signature / ".socket.sock")
    candidates.append(Path("/tmp/hypr") / signature / ".socket.sock")

    for candidate in candidates:
        if candidate.exists():
            return candidate

    print(f"Error: Hyprland socket not found at {candidates[0]}.", file=sys.stderr)
    sys.exit(1)


def cursorpos(path: Path) -> "tuple[int, int] | None":
    # The request socket answers one command and closes, so every sample needs
    # its own connection.
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
            sock.connect(str(path))
            sock.sendall(b"cursorpos")
            reply = sock.recv(64).decode("utf-8", "replace").strip()
    except OSError:
        return None

    try:
        x, y = reply.split(",")
        return int(x), int(y)
    except ValueError:
        return None


def main() -> None:
    interval_ms = DEFAULT_INTERVAL_MS
    if len(sys.argv) > 1:
        try:
            interval_ms = max(8, int(sys.argv[1]))
        except ValueError:
            pass

    path = socket_path()
    last = None
    while True:
        position = cursorpos(path)
        if position is not None and position != last:
            last = position
            print(f"{position[0]} {position[1]}", flush=True)
        time.sleep(interval_ms / 1000)


if __name__ == "__main__":
    main()
