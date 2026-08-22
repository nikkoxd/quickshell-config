pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Quickshell's Quickshell.Bluetooth module only speaks org.bluez.Adapter1,
// Device1 and Battery1 -- it never registers an org.bluez.Agent1. Without an
// agent on the bus, BlueZ has nothing to authorize Device1.Pair() with, so
// pair() aborts and the device silently stays unpaired.
//
// bluetoothctl registers an agent for the lifetime of its session, so keeping
// one open (stdin held) is enough to make pairing work. NoInputNoOutput picks
// "Just Works" pairing, which is what headsets/speakers/mice expect.
Singleton {
    id: root

    Process {
        id: agent
        running: true
        command: ["bluetoothctl"]
        stdinEnabled: true

        onStarted: {
            write("agent NoInputNoOutput\n");
            write("default-agent\n");
        }

        // bluetoothctl exits if bluetoothd restarts; bring the agent back with it.
        onExited: {
            stdinEnabled = true;
            restartTimer.restart();
        }
    }

    Timer {
        id: restartTimer
        interval: 2000
        onTriggered: agent.running = true
    }
}
