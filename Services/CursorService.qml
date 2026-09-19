pragma Singleton

import Quickshell
import Quickshell.Io

// The Hyprland cursor position, in compositor layout coordinates.
//
// Neither Wayland nor Hyprland's event socket hands a shell the pointer while
// it is over someone else's surface, so the position has to be polled; the
// poller only runs while something is actually watching.
Singleton {
    id: root

    property int x: 0
    property int y: 0

    // How often the helper samples, in milliseconds.
    property int interval: 33

    // Consumers hold a subscription rather than flipping a flag, so two of them
    // cannot switch the poller off from under each other.
    property int _subscribers: 0
    readonly property bool tracking: root._subscribers > 0

    function subscribe() {
        root._subscribers++;
    }

    function unsubscribe() {
        root._subscribers = Math.max(0, root._subscribers - 1);
    }

    Process {
        id: poller
        running: root.tracking
        command: ["python3", Quickshell.shellPath("Helpers/cursorpos.py"), String(root.interval)]

        stdout: SplitParser {
            onRead: data => {
                const parts = data.split(" ");
                if (parts.length !== 2) {
                    return;
                }

                const x = parseInt(parts[0]);
                const y = parseInt(parts[1]);
                if (isNaN(x) || isNaN(y)) {
                    return;
                }

                root.x = x;
                root.y = y;
            }
        }

        stderr: SplitParser {
            onRead: data => console.log("[cursor]", data.trim())
        }
    }
}
