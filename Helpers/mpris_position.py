#!/usr/bin/env python3
"""Report a player's real MPRIS Position, repeatedly.

Quickshell fetches `org.mpris.MediaPlayer2.Player.Position` when a track or the
playback status changes and extrapolates from there with a wall clock, so a
player that is still buffering - reporting the position it has actually reached,
which is none - leaves that extrapolation counting from a start that has not
happened yet. Nothing in the QML API re-reads the property, hence this: one
process per player, printing the position it really reports, one line of seconds
per poll.
"""
import argparse
import sys
import time

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

PLAYER_IFACE = "org.mpris.MediaPlayer2.Player"
OBJECT_PATH = "/org/mpris/MediaPlayer2"
CALL_TIMEOUT = 1000


def read_position(bus, name: str) -> float:
    """The player's Position in seconds, straight off the bus."""
    reply = bus.call_sync(
        name,
        OBJECT_PATH,
        "org.freedesktop.DBus.Properties",
        "Get",
        GLib.Variant("(ss)", (PLAYER_IFACE, "Position")),
        GLib.VariantType("(v)"),
        # Reading a position is never a reason to start a player that has quit.
        Gio.DBusCallFlags.NO_AUTO_START,
        CALL_TIMEOUT,
        None,
    )
    return reply.unpack()[0] / 1_000_000


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bus", required=True, help="player's dbus name")
    parser.add_argument("--interval", type=float, default=0.5,
                        help="seconds between reads (default 0.5)")
    parser.add_argument("--once", action="store_true", help="read once and exit")
    args = parser.parse_args()

    try:
        bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    except GLib.Error as e:
        print(f"could not connect to the session bus: {e.message}", file=sys.stderr)
        return 1

    while True:
        try:
            position = read_position(bus, args.bus)
        except GLib.Error as e:
            # The player going away is the ordinary end of this process, not a failure.
            print(f"{args.bus}: {e.message}", file=sys.stderr)
            return 0

        print(f"{position:.3f}", flush=True)
        if args.once:
            return 0
        time.sleep(args.interval)


if __name__ == "__main__":
    sys.exit(main())
