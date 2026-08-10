import QtQuick
import QtQuick.Effects
import qs.Core

// Hover label drawn on the dock's own (screen-sized) surface. Purely visual, so
// unlike the dock and the context menu it stays out of the input mask.
Item {
    id: root

    property string name: ""
    property string appId: ""

    implicitWidth: column.implicitWidth + 20
    implicitHeight: column.implicitHeight + 12
    visible: false

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Config.colorscheme.bg
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#af1a1a1a"
            shadowVerticalOffset: 4
            shadowBlur: 0.6
            autoPaddingEnabled: true
        }
    }

    Column {
        id: column
        anchors.centerIn: parent
        spacing: 2

        ThemedText {
            text: root.name
            anchors.horizontalCenter: parent.horizontalCenter
        }

        ThemedText {
            text: root.appId
            visible: text !== "" && text !== root.name
            color: Config.colorscheme.dim
            font.pixelSize: Config.theme.fontSize * 0.85
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
