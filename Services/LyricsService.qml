pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string currentText: ""

    Process {
        id: lyricsProcess
        command: ["lrcsnc"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const cleanText = data.replace(/\x1B\[[0-9;]*[a-zA-Z]/g, "").trim();
                root.currentText = cleanText;
            }
        }
    }
}
