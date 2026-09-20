#!/usr/bin/env python3
"""Bundle a rendered Telegram palette and the current wallpaper into a
.tdesktop-theme archive.

A Telegram Desktop theme is a zip holding `colors.tdesktop-theme` plus an
optional `background.jpg` (or `tiled.jpg`), which Telegram uses as the chat
background. The shell's template only renders the palette, so this turns that
palette into the archive Telegram actually imports.
"""
import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WALLPAPER_CONFIG = ROOT / "Config/wallpaper.json"
VIDEO_TYPES = {"video", "mpvpaper"}

# What a bare --solid fills with: the palette's own window background, so the
# chat area matches whatever the generator just produced.
DEFAULT_SOLID_KEY = "windowBg"

# Telegram scales the background to fill, so a flat color needs no more than a
# small tile; a photo wants enough resolution to survive that scaling.
DEFAULT_SIZE = "1920x1080"
DEFAULT_SOLID_SIZE = "256x256"


def die(message: str) -> None:
    print(f"telegram-theme: {message}", file=sys.stderr)
    sys.exit(1)


def warn(message: str) -> None:
    print(f"telegram-theme: {message}", file=sys.stderr)


def magick(args: list[str]) -> None:
    # IM7 ships `magick`, IM6 only `convert`; both take the same arguments here.
    binary = shutil.which("magick") or shutil.which("convert")

    if not binary:
        die("ImageMagick ('magick' or 'convert') not found")

    subprocess.run([binary] + args, check=True)


PALETTE_ENTRY = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([^;]+);")
HEX_COLOR = re.compile(r"^#(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$")


def palette_colors(palette: Path) -> dict[str, str]:
    """The palette's `key: value;` pairs, with aliases followed to a color.

    Telegram lets one key name another instead of a literal, so a lookup walks
    the chain until it lands on a `#rrggbb` (guarding against a cycle).
    """
    raw: dict[str, str] = {}

    for line in palette.read_text(encoding="utf-8").splitlines():
        line = line.split("//")[0]
        match = PALETTE_ENTRY.match(line)

        if match:
            raw[match.group(1)] = match.group(2).strip()

    resolved: dict[str, str] = {}

    for key in raw:
        value, seen = raw[key], {key}

        while not HEX_COLOR.match(value) and value in raw and value not in seen:
            seen.add(value)
            value = raw[value]

        if HEX_COLOR.match(value):
            resolved[key] = value

    return resolved


def opaque(color: str) -> str:
    """Drop a palette color's alpha — a flat fill has nothing to blend with."""
    if len(color) == 9:
        return color[:7]

    if len(color) == 5:
        return color[:4]

    return color


def config_wallpaper() -> tuple[str, str]:
    """The wallpaper the shell currently has set, as (path, type)."""
    try:
        data = json.loads(WALLPAPER_CONFIG.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        warn(f"could not read {WALLPAPER_CONFIG}: {error}")
        return "", ""

    return str(data.get("current", "")), str(data.get("type", ""))


def frame_from_video(source: Path, destination: Path) -> bool:
    """Grab a still out of a video wallpaper so it can still be a background."""
    if not shutil.which("ffmpeg"):
        warn("ffmpeg not found; video wallpaper cannot be used as a background")
        return False

    result = subprocess.run(
        ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-ss", "1",
         "-i", str(source), "-frames:v", "1", "-update", "1", "-q:v", "2",
         str(destination)],
        check=False,
    )

    if result.returncode != 0 or not destination.is_file():
        warn(f"ffmpeg could not extract a frame from {source}")
        return False

    return True


def solid_color(args, colors: dict[str, str]) -> str | None:
    """The fill --solid asks for: a literal color, or one the palette generated."""
    if HEX_COLOR.match(args.solid):
        return args.solid

    color = colors.get(args.solid)

    if not color:
        warn(f"palette has no color named {args.solid}; falling back to the wallpaper")
        return None

    return opaque(color)


def build_background(args, colors: dict[str, str], workdir: Path, name: str) -> Path | None:
    """Render the background image entry, or None to ship colors only."""
    target = workdir / name

    if args.solid:
        color = solid_color(args, colors)

        if color:
            magick(["-size", args.size or DEFAULT_SOLID_SIZE, f"xc:{color}", str(target)])
            return target

    wallpaper, wallpaper_type = args.wallpaper, args.wallpaper_type

    if not wallpaper:
        wallpaper, wallpaper_type = config_wallpaper()

    if not wallpaper:
        warn("no wallpaper configured; shipping colors only")
        return None

    source = Path(wallpaper.replace("file://", "")).expanduser()

    if not source.is_file():
        warn(f"wallpaper not found: {source}")
        return None

    if wallpaper_type in VIDEO_TYPES or source.suffix.lower() in {".mp4", ".webm", ".mkv", ".mov", ".avi"}:
        frame = workdir / "frame.jpg"

        if not frame_from_video(source, frame):
            return None

        source = frame

    filters = ["-resize", args.size or DEFAULT_SIZE]

    if args.blur > 0:
        filters += ["-blur", f"0x{args.blur}"]

    if args.dim > 0:
        filters += ["-fill", "black", "-colorize", f"{args.dim}%"]

    try:
        magick([str(source)] + filters + ["-quality", str(args.quality), str(target)])
    except subprocess.CalledProcessError:
        warn(f"could not convert {source} into a background")
        return None

    return target


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--palette", required=True, help="rendered .tdesktop-palette to bundle")
    parser.add_argument("--output", required=True, help="path of the .tdesktop-theme to write")
    parser.add_argument("--wallpaper", default="", help="background image (default: the shell's current wallpaper)")
    parser.add_argument("--wallpaper-type", default="", help="'image' or 'video'; inferred when omitted")
    parser.add_argument("--solid", nargs="?", const=DEFAULT_SOLID_KEY, default="",
                        help="fill the background with a flat color instead of an image: a #rrggbb "
                             f"literal, or a palette key to take the generated color from "
                             f"(default: {DEFAULT_SOLID_KEY})")
    parser.add_argument("--tiled", action="store_true", help="tile the background instead of filling the chat")
    parser.add_argument("--blur", type=float, default=0, help="blur radius applied to the background")
    parser.add_argument("--dim", type=float, default=0, help="darken the background by this percentage")
    parser.add_argument("--size", default="",
                        help=f"background size (default: {DEFAULT_SIZE}, or {DEFAULT_SOLID_SIZE} for --solid)")
    parser.add_argument("--quality", type=int, default=88, help="background JPEG quality")
    args = parser.parse_args()

    palette = Path(args.palette).expanduser()

    if not palette.is_file():
        die(f"palette not found: {palette}")

    output = Path(args.output).expanduser()
    output.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as temp:
        workdir = Path(temp)
        background = build_background(args, palette_colors(palette), workdir,
                                      "tiled.jpg" if args.tiled else "background.jpg")

        # Written to a sibling first so a failure halfway never leaves Telegram
        # pointed at a truncated archive.
        staged = output.with_suffix(output.suffix + ".new")

        with zipfile.ZipFile(staged, "w", zipfile.ZIP_DEFLATED) as archive:
            archive.write(palette, "colors.tdesktop-theme")

            if background:
                archive.write(background, background.name)

        staged.replace(output)

    print(f"telegram-theme: wrote {output}")


if __name__ == "__main__":
    main()
