#!/usr/bin/env python3
"""Fill in the parts of an SDDM theme config the color generator cannot.

The template only knows colors. This hook adds what comes from the shell's own
settings instead: the current wallpaper as `background`, the font as
`fontFamily`/`fontSize`, and the island's corner `radius`.

SDDM runs as its own user, which cannot read a 700 home directory, so the
theme cannot point at the wallpaper where it lives; it needs its own copy
inside the theme directory. The file is copied as is, keeping its extension,
which is also why the template cannot write the `background` key itself.
"""
import argparse
import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / "Config"


def die(message: str) -> None:
    print(f"sddm-theme: {message}", file=sys.stderr)
    sys.exit(1)


def warn(message: str) -> None:
    print(f"sddm-theme: {message}", file=sys.stderr)


def read_config(name: str) -> dict:
    path = CONFIG / f"{name}.json"

    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        warn(f"could not read {path}: {error}")
        return {}


def copy_wallpaper(wallpaper: str, theme: Path, name: str) -> str | None:
    """Copy the wallpaper into the theme; returns its path relative to the theme."""
    if not wallpaper:
        warn("no wallpaper configured")
        return None

    source = Path(wallpaper.replace("file://", "")).expanduser()

    if not source.is_file():
        warn(f"wallpaper not found: {source}")
        return None

    relative = name + source.suffix.lower()
    output = theme / relative
    output.parent.mkdir(parents=True, exist_ok=True)

    # Written to a sibling first so the greeter never reads a half-written file.
    staged = output.with_name(output.name + ".new")
    shutil.copyfile(source, staged)
    # The greeter reads it as another user.
    staged.chmod(0o644)
    staged.replace(output)

    # A wallpaper with a different extension leaves the previous copy behind.
    stem = Path(name).name
    for stale in output.parent.glob(f"{stem}.*"):
        if stale != output and not stale.name.endswith(".new"):
            stale.unlink()

    return relative


def set_keys(config: Path, values: dict[str, str]) -> None:
    """Write `values` at the top of [General], replacing any earlier copies."""
    lines = config.read_text(encoding="utf-8").splitlines() if config.is_file() else []
    keys = re.compile(r"^\s*(" + "|".join(map(re.escape, values)) + r")\s*=")
    lines = [line for line in lines if not keys.match(line)]
    entries = [f"{key}={value}" for key, value in values.items()]

    try:
        general = next(i for i, line in enumerate(lines) if line.strip() == "[General]")
    except StopIteration:
        lines = ["[General]"] + entries + ([""] if lines else []) + lines
    else:
        lines[general + 1:general + 1] = entries

    staged = config.with_name(config.name + ".new")
    staged.write_text("\n".join(lines) + "\n", encoding="utf-8")
    staged.chmod(0o644)
    staged.replace(config)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--theme", required=True, help="the SDDM theme directory")
    parser.add_argument("--config", default="theme.conf.user", help="config file inside the theme to update")
    parser.add_argument("--name", default="assets/wall", help="where the wallpaper goes inside the theme, without extension")
    parser.add_argument("--wallpaper", default="", help="source file (default: the shell's current wallpaper)")
    args = parser.parse_args()

    theme = Path(args.theme).expanduser()

    if not theme.is_dir():
        die(f"theme directory not found: {theme}")

    values: dict[str, str] = {}

    background = copy_wallpaper(args.wallpaper or str(read_config("wallpaper").get("current", "")), theme, args.name)
    if background:
        values["background"] = f'"{background}"'

    font = read_config("theme")
    if "fontFamily" in font:
        values["fontFamily"] = f'"{font["fontFamily"]}"'
    if "fontSize" in font:
        values["fontSize"] = str(font["fontSize"])

    island = read_config("island")
    if "radius" in island:
        values["radius"] = str(island["radius"])

    set_keys(theme / args.config, values)
    print(f"sddm-theme: updated {theme / args.config}")


if __name__ == "__main__":
    main()
