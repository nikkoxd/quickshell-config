#!/usr/bin/env python3
"""Merge a rendered KDE color scheme into ~/.config/kdeglobals.

Dolphin and every other KDE app take their palette from kdeglobals through
KColorScheme, ignoring the qt5ct/qt6ct palette the qtct.conf template writes.
kdeglobals also holds settings that have nothing to do with color, though
(the terminal application, the icon theme, per-app overrides), so the
template renders a standalone color scheme and this merges only its color
groups in, leaving everything else in the file untouched.

It also converts the scheme's `#rrggbb` values into the `r,g,b` triples
KConfig reads back as a QColor, and pokes the running apps afterwards so the
new palette lands without a restart.
"""
import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

# The groups the scheme owns. Anything else already in kdeglobals is the
# user's and is copied through untouched.
COLOR_GROUPS = re.compile(r"^(Colors:|ColorEffects:|WM$)")

# Within [General], only the scheme's identity is ours to overwrite.
GENERAL_KEYS = ("ColorScheme", "Name")

HEX = re.compile(r"^#([0-9a-fA-F]{6})$")


def die(message: str) -> None:
    print(f"kde-theme: {message}", file=sys.stderr)
    sys.exit(1)


def warn(message: str) -> None:
    print(f"kde-theme: {message}", file=sys.stderr)


def parse(text: str) -> "list[tuple[str, list[tuple[str, str]]]]":
    """Read a KConfig ini into [(group, [(key, value), ...]), ...].

    Ordered pairs rather than dicts: rewriting kdeglobals should not reshuffle
    the groups the user put there.
    """
    groups: "list[tuple[str, list[tuple[str, str]]]]" = []
    current: "list[tuple[str, str]]" = []
    groups.append(("", current))
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith(("#", ";")):
            continue
        if stripped.startswith("["):
            current = []
            groups.append((stripped.strip("[]").strip(), current))
            continue
        key, sep, value = stripped.partition("=")
        if not sep:
            continue
        current.append((key.strip(), value.strip()))
    return [(name, entries) for name, entries in groups if name or entries]


def as_rgb(value: str) -> str:
    """#rrggbb -> r,g,b. Anything else is passed through as written."""
    match = HEX.match(value)
    if not match:
        return value
    digits = match.group(1)
    return ",".join(str(int(digits[i:i + 2], 16)) for i in (0, 2, 4))


def render(groups) -> str:
    out = []
    for name, entries in groups:
        if not entries:
            continue
        if name:
            out.append(f"[{name}]")
        out.extend(f"{key}={value}" for key, value in entries)
        out.append("")
    return "\n".join(out)


def merge(target: str, scheme) -> str:
    """Replace the scheme's groups in `target`, keeping the rest in place."""
    incoming = {
        name: [(key, as_rgb(value)) for key, value in entries]
        for name, entries in scheme
        if COLOR_GROUPS.match(name)
    }
    identity = dict(
        pair
        for name, entries in scheme
        if name == "General"
        for pair in entries
        if pair[0] in GENERAL_KEYS
    )

    merged = []
    for name, entries in parse(target):
        if name in incoming:
            merged.append((name, incoming.pop(name)))
        elif COLOR_GROUPS.match(name):
            # A color group the scheme no longer defines: drop it, or a
            # leftover from a previous theme keeps overriding the new one.
            continue
        elif name == "General":
            kept = [pair for pair in entries if pair[0] not in identity]
            merged.append((name, kept + list(identity.items())))
            identity = {}
        else:
            merged.append((name, entries))

    if identity:
        merged.append(("General", list(identity.items())))
    merged.extend(incoming.items())
    return render(merged)


def notify() -> None:
    """Tell the running KDE apps their palette changed.

    The dbus signal is what KF5/KF6 apps listen to for a palette change;
    kwriteconfig's --notify additionally fires the KConfig watch, which is
    what the apps that reread kdeglobals themselves are waiting on. Neither
    is fatal if the tool is missing — the theme still applies on restart.
    """
    signal = [
        "dbus-send", "--session", "--type=signal",
        "/KGlobalSettings", "org.kde.KGlobalSettings.notifyChange",
        "int32:0", "int32:0",
    ]
    poke = [
        "kwriteconfig6", "--file", "kdeglobals",
        "--group", "General", "--key", "ColorScheme", "--notify", "Island",
    ]
    for command in (signal, poke):
        try:
            subprocess.run(command, check=True, capture_output=True)
        except FileNotFoundError:
            warn(f"{command[0]} not found; apps will pick the theme up on restart")
        except subprocess.CalledProcessError as error:
            warn(f"{command[0]} failed: {error.stderr.decode().strip()}")


def main() -> None:
    default_target = Path(
        os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")
    ) / "kdeglobals"

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--scheme", required=True,
        help="the rendered color scheme to merge in",
    )
    parser.add_argument(
        "--output", default=str(default_target),
        help="the kdeglobals to merge it into (default: ~/.config/kdeglobals)",
    )
    parser.add_argument(
        "--no-notify", action="store_true",
        help="write the file without poking the running apps",
    )
    args = parser.parse_args()

    scheme_path = Path(args.scheme).expanduser()
    if not scheme_path.is_file():
        die(f"no scheme at {scheme_path}")
    target_path = Path(args.output).expanduser()

    scheme = parse(scheme_path.read_text())
    existing = target_path.read_text() if target_path.is_file() else ""

    target_path.parent.mkdir(parents=True, exist_ok=True)
    target_path.write_text(merge(existing, scheme))

    if not args.no_notify:
        notify()


if __name__ == "__main__":
    main()
