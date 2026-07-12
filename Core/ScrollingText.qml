import QtQuick

Item {
    id: root
    clip: true
    width: Math.min(textInner.width, maxWidth)
    height: textInner.height
    property string text
    property int maxWidth: 300
    property bool bold: false
    property bool centered: false
    property bool isHeading: false

    ThemedText {
        id: textInner
        text: root.text
        font.bold: root.bold
        isHeading: root.isHeading
        onTextChanged: {
            x = 0;
            scrollAnim.restart();
        }

        SequentialAnimation on x {
            id: scrollAnim
            running: textInner.implicitWidth > root.width
            loops: Animation.Infinite

            PauseAnimation { duration: 2000 }

            PropertyAnimation {
                to: root.width - textInner.implicitWidth
                duration: Math.max(1000, (textInner.implicitWidth - root.width) * 20)
                easing.type: Easing.InOutQuad
            }

            PauseAnimation { duration: 2000 }

            PropertyAnimation {
                to: 0
                duration: Math.max(1000, (textInner.implicitWidth - root.width) * 20)
                easing.type: Easing.InOutQuad
            }
        }
    }
}
