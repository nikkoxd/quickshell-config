#!/usr/bin/env python3
"""Print the PipeWire audio playback streams as compact JSON.

`pw-dump` answers with every object PipeWire knows about - a few hundred
kilobytes - so filtering happens here and only the handful of fields a caller
needs to recognise an application comes back. One object per playback stream:

    [{"node": "alsa_playback.sonora", "app": "PipeWire ALSA [sonora]",
      "binary": "sonora", "id": "", "media": "ALSA Playback"}]

`node` is the `node.name` cava wants for `[input] source`.
"""
import json
import subprocess
import sys

STREAM_CLASS = "Stream/Output/Audio"


def dump() -> list:
    try:
        result = subprocess.run(
            ["pw-dump"], capture_output=True, text=True, timeout=5, check=True
        )
    except (OSError, subprocess.SubprocessError) as e:
        print(f"Error: pw-dump failed: {e}", file=sys.stderr)
        sys.exit(1)
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as e:
        print(f"Error: could not parse pw-dump output: {e}", file=sys.stderr)
        sys.exit(1)


def main() -> None:
    streams = []
    for obj in dump():
        if obj.get("type") != "PipeWire:Interface:Node":
            continue
        props = (obj.get("info") or {}).get("props") or {}
        if props.get("media.class") != STREAM_CLASS:
            continue
        name = props.get("node.name", "")
        if not name:
            continue
        streams.append({
            "node": name,
            "app": props.get("application.name", ""),
            "binary": props.get("application.process.binary", ""),
            "id": props.get("application.id", ""),
            "media": props.get("media.name", ""),
        })

    json.dump(streams, sys.stdout, ensure_ascii=False)
    print()


if __name__ == "__main__":
    main()
