import QtQuick

Item {
    id: root
    implicitWidth: 65
    implicitHeight: 40

    property bool checked: false

    // Emitted only when the user actually flips the toggle. Deliberately not
    // driven off a `checked` change: bindings resolve on load, so an
    // onCheckedChanged-based signal fires once at startup and writes the
    // config back over itself.
    signal toggled(bool checked)

    // On the root rather than the track so the hit area matches the full
    // control size, as the Controls.Switch it replaces did.
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        gesturePolicy: TapHandler.WithinBounds
        onTapped: root.toggled(!root.checked)
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 7
        color: Config.colorscheme.surface
        radius: height

        Rectangle {
            x: root.checked ? parent.width - width : 0
            height: parent.height
            width: parent.height
            radius: parent.height
            color: root.checked ? Config.colorscheme.accent : Config.colorscheme.fg

            Behavior on x {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutQuart
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
