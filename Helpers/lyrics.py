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

try:
    import yaml
except ModuleNotFoundError:
    # Only LRCLIB's word-synced `lyricsfile` is YAML; everything else works without it.
    yaml = None

API_BASE = "https://lrclib.net/api"
USER_AGENT = "quickshell-island (https://github.com/nikkoxd/island)"
DEFAULT_TIMEOUT = 8.0

CACHE_DIR = Path(
    os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")
) / "island/lyrics"
# Hits are kept forever; misses expire so a track LRCLIB gains later is picked up.
MISS_TTL = 24 * 60 * 60
# Bumped whenever the payload shape changes, so hits cached by an older version
# (which are kept forever) are refetched instead of read back missing fields.
SCHEMA = 2

# [mm:ss], [mm:ss.xx] and [mm:ss.xxx]
TIMESTAMP_RE = re.compile(r"\[(\d+):(\d{1,2})(?:[.:](\d{1,3}))?\]")
OFFSET_RE = re.compile(r"\[offset:\s*([+-]?\d+)\s*\]", re.IGNORECASE)
# Enhanced LRC ("A2") word stamps: <mm:ss.xx> in front of each word of a line.
WORD_RE = re.compile(r"<(\d+):(\d{1,2})(?:[.:](\d{1,3}))?>")
# Longest window an unstamped last word is swept over, so it doesn't crawl
# through the instrumental gap its line happens to end in.
WORD_TAIL = 2.0
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
    if data.get("schema") != SCHEMA:
        return None
    if not data.get("found") and time.time() - data.get("cached_at", 0) > MISS_TTL:
        return None
    return data


def cache_write(path: Path, payload: dict) -> None:
    record = dict(payload, cached_at=time.time(), schema=SCHEMA)
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


def stamp_seconds(minutes: str, seconds: str, fraction: str | None) -> float:
    t = int(minutes) * 60 + int(seconds)
    if fraction:
        t += int(fraction) / (10 ** len(fraction))
    return t


def word_spans(text: str, words: list[dict]) -> list[dict]:
    """Close the character ranges of `words`, which carry only their own start.

    A word runs up to where the next one begins, so the space between two words
    is swept as part of the first instead of being jumped over.
    """
    for i, word in enumerate(words):
        word["to"] = words[i + 1]["from"] if i + 1 < len(words) else len(text)
    return [word for word in words if 0 <= word["from"] < word["to"]]


def split_enhanced(body: str) -> tuple[str, list[dict] | None]:
    """Split an enhanced-LRC line body into its text and its word stamps.

    Words carry character offsets into the returned text rather than a copy of
    it, so the shell can measure the line it already drew instead of matching
    strings back onto it. Returns (text, None) for a line without word stamps.
    """
    stamps = list(WORD_RE.finditer(body))
    if not stamps:
        return body.strip(), None

    # Anything before the first stamp is a lead-in nobody timed.
    text = body[:stamps[0].start()]
    words: list[dict] = []

    for i, stamp in enumerate(stamps):
        end = stamps[i + 1].start() if i + 1 < len(stamps) else len(body)
        segment = body[stamp.end():end]
        time = stamp_seconds(*stamp.groups())

        if segment.strip():
            # Start the word at its first glyph, not at the space before it.
            lead = len(segment) - len(segment.lstrip())
            words.append({"time": time, "from": len(text) + lead})
        elif words:
            # A stamp with nothing after it closes the last word off.
            words[-1]["end"] = time

        text += segment

    # Trimming the line shifts every offset in it along.
    lead = len(text) - len(text.lstrip())
    text = text.strip()
    for word in words:
        word["from"] = min(max(0, word["from"] - lead), len(text))

    words = word_spans(text, words)
    return text, words or None


def shifted(words: list[dict], shift: float) -> list[dict]:
    """Copy `words` onto a timeline `shift` seconds later."""
    out = []
    for word in words:
        moved = {"time": round(word["time"] + shift, 3),
                 "from": word["from"],
                 "to": word["to"]}
        if "end" in word:
            moved["end"] = round(word["end"] + shift, 3)
        out.append(moved)
    return out


def close_windows(lines: list[dict]) -> None:
    """Give every line and word the end time a karaoke fill needs to stop at.

    A word ends at its own stamp where it has one, but never later than the next
    word starts: the fill lands exactly on the boundary that way instead of being
    dragged across it, and a pause after a word still holds the fill still.
    """
    for i, line in enumerate(lines):
        if line.get("end") is None:
            line["end"] = lines[i + 1]["time"] if i + 1 < len(lines) else None

        words = line.get("words")
        if not words:
            continue

        for j, word in enumerate(words):
            last = j + 1 == len(words)
            nxt = line["end"] if last else words[j + 1]["time"]
            if word.get("end") is None:
                tail = word["time"] + WORD_TAIL
                word["end"] = tail if nxt is None else min(nxt, tail) if last else nxt
            elif nxt is not None:
                word["end"] = min(word["end"], nxt)


def parse_lrc(lrc: str, offset: float = 0.0) -> list[dict]:
    """Parse LRC text into a time-sorted list of {"time", "text"} entries.

    Enhanced LRC also yields a "words" list of {"time", "from", "to"} per line.
    """
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

        text, words = split_enhanced(raw[stamps[-1].end():])
        times = [stamp_seconds(*stamp.groups()) for stamp in stamps]

        for t in times:
            line = {"time": round(t + tag_offset + offset, 3), "text": text}
            if words:
                # One body can be stamped several times; its words move with each copy.
                line["words"] = shifted(words, t - times[0] + tag_offset + offset)
            lines.append(line)

    lines.sort(key=lambda line: line["time"])
    return lines


def as_text(value) -> str:
    return value.strip() if isinstance(value, str) else ""


def as_seconds(value) -> float | None:
    """Seconds from a lyricsfile timestamp, which is text under the plain loader."""
    try:
        return float(value) / 1000.0
    except (TypeError, ValueError):
        return None


def align_words(text: str, words, offset: float) -> list[dict] | None:
    """Map word-synced entries onto character ranges in `text`.

    Bails out entirely if a word isn't where it should be - half an alignment
    would run the fill over the wrong glyphs.
    """
    if not isinstance(words, list) or not words:
        return None

    spans = []
    cursor = 0
    for word in words:
        if not isinstance(word, dict):
            return None
        piece = as_text(word.get("text"))
        start = as_seconds(word.get("start_ms"))
        if not piece or start is None:
            return None

        at = text.find(piece, cursor)
        if at < 0:
            return None

        span = {"time": round(start + offset, 3), "from": at}
        end = as_seconds(word.get("end_ms"))
        if end is not None:
            span["end"] = round(end + offset, 3)
        spans.append(span)
        cursor = at + len(piece)

    return word_spans(text, spans) or None


def parse_lyricsfile(raw: str, offset: float = 0.0) -> list[dict]:
    """Parse LRCLIB's `lyricsfile`, the YAML document its word timings live in."""
    if not raw or yaml is None:
        return []

    try:
        # Every scalar comes back as text: a word sung as "Yes" or "No" is a YAML
        # boolean to the usual loader, and one sung as a year is an int.
        data = yaml.load(raw, Loader=yaml.BaseLoader)
    except yaml.YAMLError as e:
        print(f"Warning: could not parse lyricsfile: {e}", file=sys.stderr)
        return []

    if not isinstance(data, dict):
        return []

    lines = []
    for entry in data.get("lines") or []:
        if not isinstance(entry, dict):
            continue
        start = as_seconds(entry.get("start_ms"))
        if start is None:
            continue

        text = as_text(entry.get("text"))
        line = {"time": round(start + offset, 3), "text": text}

        end = as_seconds(entry.get("end_ms"))
        if end is not None:
            line["end"] = round(end + offset, 3)

        words = align_words(text, entry.get("words"), offset)
        if words:
            line["words"] = words

        lines.append(line)

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
        "words": False,
        "error": None,
    }


def worded(lines: list[dict]) -> bool:
    return any(line.get("words") for line in lines)


def build_payload(track: dict, offset: float) -> dict:
    lines = parse_lrc(track.get("syncedLyrics") or "", offset)

    # LRCLIB keeps word timings in the lyricsfile, and the LRC for the same track
    # is usually line-synced only - so take the lyricsfile when it has words the
    # LRC doesn't, both being renderings of the same lyrics.
    if not worded(lines):
        detailed = parse_lyricsfile(track.get("lyricsfile") or "", offset)
        if worded(detailed) or not lines:
            lines = detailed or lines

    close_windows(lines)

    return {
        "found": True,
        "synced": bool(lines),
        "instrumental": bool(track.get("instrumental")),
        "source": "lrclib",
        "title": track.get("trackName") or "",
        "artist": track.get("artistName") or "",
        "album": track.get("albumName") or "",
        "duration": track.get("duration"),
        "lines": lines,
        "plain": track.get("plainLyrics") or "",
        "words": worded(lines),
        "error": None,
    }


def get_lyrics(args) -> dict:
    """Resolve lyrics for the requested track, consulting the cache first."""
    path = cache_path(args.title, args.artist, args.album, args.duration)

    if not args.no_cache and not args.refresh:
        cached = cache_read(path)
        if cached is not None:
            cached.pop("cached_at", None)
            cached.pop("schema", None)
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
