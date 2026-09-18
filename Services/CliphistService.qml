pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Decoded image previews live in the cache dir, not Config/, since they are
    // reproducible copies of clipboard content rather than user settings.
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/island/cliphist"

    // Newest previews kept on disk; older ones are pruned on every fetch.
    readonly property int maxPreviews: 200

    // cliphist renders non-text entries as `[[ binary data 52 KiB png 923x495 ]]`.
    // Only the shape carrying pixel dimensions is an image we can preview.
    readonly property var binaryRe: /^\[\[\s*binary data\s+([\d.]+)\s+(\w+)\s+(\w+)\s+(\d+)x(\d+)\s*\]\]$/
    readonly property var imageExtensions: ["png", "jpg", "jpeg", "gif", "webp", "bmp"]

    property var entries: []

    // previewKey -> "file://..." of the decoded image. Reassigned wholesale, never
    // mutated in place, so delegate bindings re-evaluate as previews land.
    property var previews: ({})

    // previewKey -> cliphist id, so a delegate only has to carry the key.
    property var previewIds: ({})

    // Decoding is lazy: the list can hold hundreds of images, so only the entries a
    // delegate actually asks for are decoded, one process at a time.
    property var queue: []
    property bool decoding: false

    function startListener() {
        listenProc.running = true;
    }

    function fetch() {
        console.log("[cliphist] Fetching clipboard history");
        pruneProc.running = true;
        listProc.running = true;
    }

    function wipe() {
        root.previews = ({});
        root.previewIds = ({});
        root.queue = [];
        wipeProc.running = true;
    }

    function decodeAndCopy(id, mimeType) {
        if (!/^\d+$/.test(String(id)))
            return;
        const copy = mimeType ? "wl-copy --type " + mimeType : "wl-copy";
        copyProc.command = ["sh", "-c", "cliphist decode " + id + " | " + copy];
        copyProc.running = true;
    }

    // Requests the image behind `key` be decoded to disk, if it isn't already.
    // Safe to call repeatedly — delegates call it every time they are recycled.
    function ensureDecoded(key) {
        if (!key || root.previews[key] !== undefined || root.queue.indexOf(key) !== -1)
            return;
        root.queue.push(key);
        drainQueue();
    }

    function drainQueue() {
        if (root.decoding || root.queue.length === 0)
            return;
        const key = root.queue.shift();
        const id = root.previewIds[key];
        if (id === undefined) {
            drainQueue();
            return;
        }
        root.decoding = true;
        decodeProc.key = key;
        decodeProc.command = ["sh", "-c",
            'mkdir -p "$0"; if [ ! -s "$0/$1" ]; then cliphist decode "$2" > "$0/$1" || rm -f "$0/$1"; fi',
            root.cacheDir, key, String(id)];
        decodeProc.running = true;
    }

    Process {
        id: listenProc
        command: ["wl-paste", "--watch", "cliphist", "store"]
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text.split("\n");
                const list = [];
                const ids = ({});

                for (let i = 0; i < out.length; i++) {
                    // Only the first tab separates id from value; a copied snippet
                    // may well contain tabs of its own.
                    const sep = out[i].indexOf("\t");
                    if (sep === -1)
                        continue;
                    const id = out[i].slice(0, sep);
                    const value = out[i].slice(sep + 1);
                    if (!id || !value)
                        continue;

                    const binary = root.binaryRe.exec(value);
                    const extension = binary ? binary[3].toLowerCase() : "";

                    if (binary && root.imageExtensions.indexOf(extension) !== -1) {
                        const size = binary[1] + " " + binary[2];
                        const width = binary[4];
                        const height = binary[5];
                        // Dimensions and size make the key self-invalidating, so a
                        // reused id (cliphist restarts numbering after a wipe) can't
                        // serve a stale preview.
                        const key = id + "-" + width + "x" + height + "-"
                                  + size.replace(/\s+/g, "") + "." + extension;
                        const mimeType = "image/" + (extension === "jpg" ? "jpeg" : extension);
                        ids[key] = id;
                        list.push({
                            name: extension + " · " + width + "×" + height + " · " + size,
                            search: ("image " + extension + " " + width + "x" + height).toLowerCase(),
                            previewKey: key,
                            isImage: true,
                            execute: function() {
                                root.decodeAndCopy(id, mimeType);
                            }
                        });
                        continue;
                    }

                    list.push({
                        name: value,
                        search: value.toLowerCase(),
                        isImage: false,
                        execute: function() {
                            root.decodeAndCopy(id, "");
                        }
                    });
                }

                root.previewIds = ids;
                root.entries = list;
                // Drop previews for entries that fell out of the history, so a
                // recycled key can't resolve to a file from the previous owner.
                const kept = ({});
                for (const key in root.previews)
                    if (ids[key] !== undefined)
                        kept[key] = root.previews[key];
                root.previews = kept;
            }
        }
    }

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
        onExited: Quickshell.execDetached(["sh", "-c", 'rm -rf -- "$0"', root.cacheDir])
    }

    Process {
        id: copyProc
    }

    Process {
        id: pruneProc
        command: ["sh", "-c",
            'cd "$0" 2>/dev/null || exit 0; ls -1t . 2>/dev/null | tail -n +$(($1 + 1)) | while IFS= read -r f; do rm -f -- "./$f"; done',
            root.cacheDir, String(root.maxPreviews)]
    }

    Process {
        id: decodeProc
        property string key
        onExited: code => {
            root.decoding = false;
            if (code === 0) {
                const next = Object.assign({}, root.previews);
                next[decodeProc.key] = "file://" + root.cacheDir + "/" + decodeProc.key;
                root.previews = next;
            } else {
                console.warn("[cliphist] Failed to decode preview:", decodeProc.key);
            }
            root.drainQueue();
        }
    }
}
