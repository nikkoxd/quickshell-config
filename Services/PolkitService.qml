pragma Singleton
import Quickshell
import Quickshell.Services.Polkit
import QtQuick

// The session's polkit authentication agent. pkexec, systemctl, udisks and
// friends ask polkitd for authorization, and polkitd hands the password prompt
// to whichever agent registered for the session — this one, so the prompt
// shows up in the island rather than in a separate dialog.
//
// Only one agent can be registered per session. If another one (hyprpolkitagent,
// polkit-gnome, …) got there first, registration fails and requests keep going
// to that one; `registered` reports which.
//
// polkitd queues concurrent requests itself, so `flow` is only ever the one
// being answered right now; `requested` fires again for each one that follows.
Singleton {
    id: root

    readonly property bool registered: agent.isRegistered
    readonly property AuthFlow flow: agent.flow
    readonly property bool active: agent.isActive

    signal requested

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            console.log("[polkit] Authentication requested for", agent.flow?.actionId);
            root.requested();
        }

        onIsRegisteredChanged: {
            if (agent.isRegistered)
                console.log("[polkit] Registered as the session's authentication agent");
        }
    }

    // Registration either lands right away or never does; say so once instead
    // of leaving auth requests silently going to some other agent.
    Timer {
        interval: 3000
        running: true
        onTriggered: {
            if (!agent.isRegistered)
                console.warn("[polkit] Could not register the authentication agent; another agent is probably running");
        }
    }
}
