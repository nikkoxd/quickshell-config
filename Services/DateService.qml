pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string hours
    property string minutes
    property string date

    Process {
        id: clockHours
        command: ["date", "+%H"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.hours = this.text.trim()
        }
    }

    Process {
        id: clockMinutes
        command: ["date", "+%M"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.minutes = this.text.trim()
        }
    }

    Process {
        id: clockDate
        command: ["date", "+%A, %b %d"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.date = this.text.trim()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clockHours.running = true;
            clockMinutes.running = true;
        }
    }
}
