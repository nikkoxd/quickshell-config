#!/usr/bin/env python3
import argparse
import bisect
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API_BASE = "https://lrclib.net/api"
USER_AGENT = "quickshell-island (https://github.com/nikkoxd/island)"
DEFAULT_TIMEOUT = 8.0

CACHE_DIR = Path(
    os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")
) / "island/lyrics"
# Hits are kept forever; misses expire so a track LRCLIB gains later is picked up.
MISS_TTL = 24 * 60 * 60

# [mm:ss], [mm:ss.xx] and [mm:ss.xxx]
TIMESTAMP_RE = re.compile(r"\[(\d+):(\d{1,2})(?:[.:](\d{1,3}))?\]")
OFFSET_RE = re.compile(r"\[offset:\s*([+-]?\d+)\s*\]", re.IGNORECASE)
# Duration match tolerance when falling back to the search endpoint
DURATION_TOLERANCE = 5.0


def normalize(text: str) -> str:
    return " ".join((text or "").split()).lower()


def cache_path(title: str, artist: str, album: str, duration: float | None) -> Path:
    # Round the duration so trivial reporting jitter between players still hits.
    bucket = "" if duration is None else str(int(duration) // 2)
    key = "|".join([normalize(artist), normalize(title), normalize(album), bucket])
    return CACHE_DIR / f"{hashlib.sha1(key.encode('utf-8')).hexdigest()}.json"


def cache_read(path: Path) -> dict | None:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None
    if not isinstance(data, dict):
        return None
    if not data.get("found") and time.time() - data.get("cached_at", 0) > MISS_TTL:
        return None
    return data


def cache_write(path: Path, payload: dict) -> None:
    record = dict(payload, cached_at=time.time())
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        # Write via a pid-suffixed temp file so concurrent spawns can't tear the file.
        tmp = path.with_suffix(f".{os.getpid()}.tmp")
        tmp.write_text(json.dumps(record, ensure_ascii=False), encoding="utf-8")
        os.replace(tmp, path)
    except OSError as e:
        print(f"Warning: could not write cache: {e}", file=sys.stderr)


def api_get(endpoint: str, params: dict, timeout: float):
    url = f"{API_BASE}/{endpoint}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def pick_candidate(results: list, duration: float | None) -> dict | None:
    if not results:
        return None

    synced = [r for r in results if r.get("syncedLyrics")]
    pool = synced or results

    if duration is not None:
        def delta(r):
            d = r.get("duration")
            return abs(d - duration) if isinstance(d, (int, float)) else float("inf")

        best = min(pool, key=delta)
        if delta(best) <= DURATION_TOLERANCE:
            return best

    return pool[0]


def lrclib_lookup(
    title: str,
    artist: str,
    album: str,
    duration: float | None,
    timeout: float,
) -> tuple[dict | None, str | None]:
    """Return (track, error). Both None means a clean "no lyrics exist"."""
    params = {"track_name": title, "artist_name": artist}
    if album:
        params["album_name"] = album
    if duration is not None:
        params["duration"] = int(duration)

    try:
        return api_get("get", params, timeout), None
    except urllib.error.HTTPError as e:
        if e.code != 404:
            return None, f"lrclib returned HTTP {e.code}"
    except urllib.error.URLError as e:
        return None, f"network error: {e.reason}"
    except (json.JSONDecodeError, TimeoutError, OSError) as e:
        return None, f"lrclib request failed: {e}"

    # Exact match missed - fall back to fuzzy search.
    try:
        results = api_get("search", {"track_name": title, "artist_name": artist}, timeout)
    except urllib.error.HTTPError as e:
        return None, f"lrclib search returned HTTP {e.code}"
    except urllib.error.URLError as e:
        return None, f"network error: {e.reason}"
    except (json.JSONDecodeError, TimeoutError, OSError) as e:
        return None, f"lrclib search failed: {e}"

    if not isinstance(results, list):
        return None, "unexpected search response"
    return pick_candidate(results, duration), None


def parse_lrc(lrc: str, offset: float = 0.0) -> list[dict]:
    """Parse LRC text into a time-sorted list of {"time", "text"} entries."""
    if not lrc:
        return []

    tag_offset = 0.0
    tag_match = OFFSET_RE.search(lrc)
    if tag_match:
        # An LRC [offset:] tag is in milliseconds and shifts lyrics *earlier* when positive.
        tag_offset = -int(tag_match.group(1)) / 1000.0

    lines = []
    for raw in lrc.splitlines():
        stamps = list(TIMESTAMP_RE.finditer(raw))
        if not stamps:
            continue

        text = raw[stamps[-1].end():].strip()
        for stamp in stamps:
            minutes, seconds, fraction = stamp.groups()
            t = int(minutes) * 60 + int(seconds)
            if fraction:
                t += int(fraction) / (10 ** len(fraction))
            lines.append({"time": round(t + tag_offset + offset, 3), "text": text})

    lines.sort(key=lambda line: line["time"])
    return lines


def empty_payload(title: str, artist: str, album: str, duration: float | None) -> dict:
    return {
        "found": False,
        "synced": False,
        "instrumental": False,
        "source": "lrclib",
        "title": title,
        "artist": artist,
        "album": album,
        "duration": duration,
        "lines": [],
        "plain": "",
        "error": None,
    }


def build_payload(track: dict, offset: float) -> dict:
    synced = track.get("syncedLyrics") or ""
    return {
        "found": True,
        "synced": bool(synced),
        "instrumental": bool(track.get("instrumental")),
        "source": "lrclib",
        "title": track.get("trackName") or "",
        "artist": track.get("artistName") or "",
        "album": track.get("albumName") or "",
        "duration": track.get("duration"),
        "lines": parse_lrc(synced, offset),
        "plain": track.get("plainLyrics") or "",
        "error": None,
    }


def get_lyrics(args) -> dict:
    """Resolve lyrics for the requested track, consulting the cache first."""
    path = cache_path(args.title, args.artist, args.album, args.duration)

    if not args.no_cache and not args.refresh:
        cached = cache_read(path)
        if cached is not None:
            cached.pop("cached_at", None)
            cached["source"] = "cache"
            return cached

    track, error = lrclib_lookup(
        args.title, args.artist, args.album, args.duration, args.timeout
    )

    if error is not None:
        payload = empty_payload(args.title, args.artist, args.album, args.duration)
        payload["error"] = error
        # Never cache a network failure - the track may well exist.
        return payload

    if track is None:
        payload = empty_payload(args.title, args.artist, args.album, args.duration)
        payload["error"] = "no lyrics found"
    else:
        payload = build_payload(track, args.offset)

    if not args.no_cache:
        cache_write(path, payload)
    return payload


def line_at(lines: list[dict], position: float) -> dict:
    """Locate the lyric line active at `position` seconds."""
    result = {
        "found": False,
        "index": -1,
        "time": None,
        "text": "",
        "next_time": None,
        "prev_text": "",
        "next_text": "",
    }
    if not lines:
        return result

    times = [line["time"] for line in lines]
    # bisect_right - 1 gives the last line whose timestamp has already passed.
    index = bisect.bisect_right(times, position) - 1

    if index >= 0:
        result["found"] = True
        result["index"] = index
        result["time"] = lines[index]["time"]
        result["text"] = lines[index]["text"]
        if index > 0:
            result["prev_text"] = lines[index - 1]["text"]

    if index + 1 < len(lines):
        result["next_time"] = lines[index + 1]["time"]
        result["next_text"] = lines[index + 1]["text"]

    return result


def cmd_fetch(args) -> None:
    emit(get_lyrics(args))


def cmd_current(args) -> None:
    payload = get_lyrics(args)
    result = line_at(payload["lines"], args.position)
    result["error"] = payload["error"]
    emit(result)


def cmd_clear_cache(args) -> None:
    removed = 0
    if CACHE_DIR.is_dir():
        for entry in CACHE_DIR.glob("*.json"):
            if not args.all:
                data = cache_read(entry)
                if data is not None and data.get("found"):
                    continue
            try:
                entry.unlink()
                removed += 1
            except OSError:
                pass
    emit({"removed": removed, "path": str(CACHE_DIR)})


def emit(payload: dict) -> None:
    json.dump(payload, sys.stdout, ensure_ascii=False)
    print()


def add_lookup_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--title", required=True, help="track title")
    parser.add_argument("--artist", required=True, help="track artist")
    parser.add_argument("--album", default="", help="album name, improves matching")
    parser.add_argument("--duration", type=float, help="track length in seconds")
    parser.add_argument("--offset", type=float, default=0.0,
                        help="shift all timestamps by N seconds")
    parser.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT,
                        help=f"network timeout in seconds (default {DEFAULT_TIMEOUT})")
    parser.add_argument("--no-cache", action="store_true",
                        help="skip reading and writing the cache")
    parser.add_argument("--refresh", action="store_true",
                        help="ignore cached data but store the fresh result")


def main() -> None:
    parser = argparse.ArgumentParser(description="Fetch synced lyrics from LRCLIB.")
    sub = parser.add_subparsers(dest="command", required=True)

    fetch = sub.add_parser("fetch", help="print the full timestamped lyrics")
    add_lookup_args(fetch)
    fetch.set_defaults(func=cmd_fetch)

    current = sub.add_parser("current", help="print the lyric line at a given position")
    add_lookup_args(current)
    current.add_argument("--position", type=float, required=True,
                         help="playback position in seconds")
    current.set_defaults(func=cmd_current)

    clear = sub.add_parser("clear-cache", help="remove cached lyrics")
    clear.add_argument("--all", action="store_true",
                       help="also drop successful lookups, not just misses")
    clear.set_defaults(func=cmd_clear_cache)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
