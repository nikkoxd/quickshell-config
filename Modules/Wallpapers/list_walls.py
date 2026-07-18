#!/usr/bin/env python3
import json
import sys
from pathlib import Path

STEAM_DIRS = [
    Path.home() / ".steam/steam",
    Path.home() / ".local/share/Steam",
    Path.home() / ".var/app/com.valvesoftware.Steam/.local/share/Steam",
    Path.home() / "snap/steam/common/.local/share/Steam",
]
APP_ID = "431960"

VIDEO_EXTS = {".mp4", ".webm", ".avi", ".mov", ".mkv"}
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".gif"}
PREVIEW_NAMES = [
    "preview.jpg", "preview.png", "preview.jpeg", "preview.gif",
    "thumb.jpg", "thumb.png", "thumb.gif",
    "thumbnail.jpg", "thumbnail.png", "thumbnail.gif",
]


def find_workshop_dir() -> Path:
    for steam_dir in STEAM_DIRS:
        candidate = steam_dir / "steamapps/workshop/content" / APP_ID
        if candidate.is_dir():
            return candidate
    print("Error: Wallpaper Engine workshop directory not found.", file=sys.stderr)
    sys.exit(1)


def get_title(wall_dir: Path) -> str:
    proj = wall_dir / "project.json"
    if proj.is_file():
        try:
            data = json.loads(proj.read_text(encoding="utf-8"))
            return data.get("title", "")
        except (json.JSONDecodeError, OSError):
            pass
    return ""


def get_video(wall_dir: Path) -> Path | None:
    for f in wall_dir.iterdir():
        if f.is_file() and f.suffix.lower() in VIDEO_EXTS:
            return f
    return None


def get_preview(wall_dir: Path) -> Path | None:
    for name in PREVIEW_NAMES:
        candidate = wall_dir / name
        if candidate.is_file():
            return candidate
    # Fallback: any image in the folder
    for f in wall_dir.iterdir():
        if f.is_file() and f.suffix.lower() in IMAGE_EXTS:
            return f
    return None


def main() -> None:
    workshop_dir = find_workshop_dir()

    wallpapers = []
    for wall_dir in sorted(workshop_dir.iterdir()):
        if not wall_dir.is_dir():
            continue

        video = get_video(wall_dir)
        if video is None:
            continue

        id_ = wall_dir.name
        title = get_title(wall_dir) or id_
        preview = get_preview(wall_dir)
        if preview is None:
            preview = video

        wallpapers.append({
            "id": id_,
            "title": title,
            "preview": str(preview),
            "file": str(video),
            "path": str(wall_dir),
        })

    json.dump(wallpapers, sys.stdout, indent=2, ensure_ascii=False)
    print()


if __name__ == "__main__":
    main()
