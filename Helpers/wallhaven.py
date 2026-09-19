#!/usr/bin/env python3
"""Wallhaven.cc bridge for the wallpaper browser.

Two subcommands, both printing a single JSON object on stdout:

    search    query the search API and return the result page
    download  fetch one wallpaper into a folder and return its path

Errors are reported as {"ok": false, "error": "..."} with exit code 1, so the
caller never has to tell a crash apart from an empty result.
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API_URL = "https://wallhaven.cc/api/v1/search"
USER_AGENT = "quickshell-island (https://github.com/nikkoxd/island)"
DEFAULT_TIMEOUT = 15.0


def fail(message: str) -> None:
    json.dump({"ok": False, "error": message}, sys.stdout)
    print()
    sys.exit(1)


def request(url: str, timeout: float) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return response.read()


def describe(error: Exception) -> str:
    # A 200 carrying the site's own status page instead of JSON is what a
    # Wallhaven outage looks like from here, so it lands as a decode error.
    if isinstance(error, json.JSONDecodeError):
        return "Wallhaven is down :("
    if isinstance(error, urllib.error.HTTPError):
        if error.code == 401:
            return "Wallhaven rejected the API key"
        if error.code == 429:
            return "Rate limited by Wallhaven, try again in a minute"
        return f"Wallhaven returned HTTP {error.code}"
    if isinstance(error, urllib.error.URLError):
        return f"Could not reach Wallhaven: {error.reason}"
    return str(error)


def search(args: argparse.Namespace) -> None:
    params = {
        "categories": args.categories,
        "purity": args.purity,
        "sorting": args.sorting,
        "order": args.order,
        "page": str(max(1, args.page)),
    }
    if args.query:
        params["q"] = args.query
    if args.ratios:
        params["ratios"] = args.ratios
    if args.sorting == "toplist":
        params["topRange"] = args.top_range
    if args.seed:
        params["seed"] = args.seed
    if args.api_key:
        params["apikey"] = args.api_key

    url = f"{API_URL}?{urllib.parse.urlencode(params)}"

    try:
        payload = json.loads(request(url, args.timeout))
    except (urllib.error.URLError, json.JSONDecodeError, OSError) as error:
        fail(describe(error))

    meta = payload.get("meta") or {}
    results = []
    for item in payload.get("data") or []:
        thumbs = item.get("thumbs") or {}
        results.append({
            "id": item.get("id", ""),
            "url": item.get("path", ""),
            "thumb": thumbs.get("small") or thumbs.get("large") or "",
            "resolution": item.get("resolution", ""),
            "category": item.get("category", ""),
            "purity": item.get("purity", ""),
            "fileSize": item.get("file_size", 0),
        })

    json.dump({
        "ok": True,
        "results": results,
        "page": meta.get("current_page", args.page),
        "lastPage": meta.get("last_page", args.page),
        "total": meta.get("total", len(results)),
        # Carried back so paging through a random listing does not reshuffle.
        "seed": meta.get("seed", ""),
    }, sys.stdout)
    print()


def download(args: argparse.Namespace) -> None:
    name = args.name or os.path.basename(urllib.parse.urlparse(args.url).path)
    if not name:
        fail("Could not work out a file name for the download")

    dest_dir = Path(os.path.expandvars(args.dest)).expanduser()
    try:
        dest_dir.mkdir(parents=True, exist_ok=True)
    except OSError as error:
        fail(f"Could not create {dest_dir}: {error}")

    dest = dest_dir / name
    if dest.exists():
        json.dump({"ok": True, "path": str(dest), "existed": True}, sys.stdout)
        print()
        return

    try:
        data = request(args.url, args.timeout)
    except (urllib.error.URLError, OSError) as error:
        fail(describe(error))

    # Written beside the target first so a partial download is never left
    # behind for the folder model to pick up as a wallpaper.
    tmp = dest.with_name(f".{dest.name}.{os.getpid()}.part")
    try:
        tmp.write_bytes(data)
        tmp.replace(dest)
    except OSError as error:
        tmp.unlink(missing_ok=True)
        fail(f"Could not write {dest}: {error}")

    json.dump({"ok": True, "path": str(dest), "existed": False}, sys.stdout)
    print()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    search_parser = sub.add_parser("search")
    search_parser.add_argument("--query", default="")
    search_parser.add_argument("--page", type=int, default=1)
    search_parser.add_argument("--categories", default="111")
    search_parser.add_argument("--purity", default="100")
    search_parser.add_argument("--sorting", default="date_added")
    search_parser.add_argument("--ratios", default="")
    search_parser.add_argument("--order", default="desc")
    search_parser.add_argument("--top-range", default="1M")
    search_parser.add_argument("--seed", default="")
    search_parser.add_argument("--api-key", default="")
    search_parser.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT)
    search_parser.set_defaults(func=search)

    download_parser = sub.add_parser("download")
    download_parser.add_argument("--url", required=True)
    download_parser.add_argument("--dest", required=True)
    download_parser.add_argument("--name", default="")
    download_parser.add_argument("--timeout", type=float, default=60.0)
    download_parser.set_defaults(func=download)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
