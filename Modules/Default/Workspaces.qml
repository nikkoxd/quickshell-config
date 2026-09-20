import QtQuick
import Quickshell.Hyprland
import qs.Core

// The workspace strip the default view shows in its centre for a moment after
// a workspace change. It used to be a view of its own, which meant a workspace
// switch replaced the whole island and took the surrounding indicators with
// it; as one of the centres it swaps with the clock alone.
//
// Special workspaces carry negative ids and come and go with a scratchpad, so
// they are left out rather than making the island jump width.
Row {
    id: root
    spacing: 5

    Repeater {
        model: Hyprland.workspaces

        // A workspace that opens grows its slot out of the strip instead of
        // shoving its neighbours aside in one frame. Closing one cannot be
        // animated the same way - Hyprland drops it from the model and the
        // delegate goes with it - so the strip only shrinks back.
        PopIn {
            id: entry
            required property var modelData

            shown: entry.modelData.id > 0
            animateOnLoad: true

            ThemedText {
                text: entry.modelData.name
                opacity: entry.modelData.active ? 1 : 0.5

                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }
}
