import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.Core

Item {
    id: root

    required property Toplevel toplevel
    property int size: 40

    // appId is the desktop-file "class"; heuristicLookup handles the common
    // mismatches (case, reverse-dns ids, StartupWMClass).
    readonly property DesktopEntry entry: DesktopEntries.heuristicLookup(toplevel.appId)

    implicitWidth: size
    implicitHeight: size + 6

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onTapped: (event) => {
            if (event.button === Qt.MiddleButton)
                root.toplevel.close();
            else
                root.toplevel.activate();
        }
    }

    IconImage {
        id: icon
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        implicitSize: root.size
        asynchronous: true
        source: {
            const name = root.entry ? root.entry.icon : root.toplevel.appId;
            return Quickshell.iconPath(name, "application-x-executable");
        }
        scale: hover.hovered ? 1.15 : 1.0
        layer.enabled: Config.dock.coloredIcons
        layer.effect: MultiEffect {
            colorization: 0.5
            colorizationColor: Config.colorscheme.dim
        }

        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    // running / focused indicator
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.toplevel.activated ? 12 : 4
        height: 4
        radius: 2
        color: root.toplevel.activated ? Config.colorscheme.accent : Config.colorscheme.fg
        opacity: root.toplevel.activated ? 1.0 : 0.4

        Behavior on width {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }
}
