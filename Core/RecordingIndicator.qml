import QtQuick
import qs.Services

// The blinking dot shown in the default views while a recording is running.
Rectangle {
    id: root
    width: 8
    height: 8
    radius: width / 2
    color: "#ff5555"
    // Extra condition on top of "a recording is running": the default views keep
    // a dot on either side of the text and let the visualizer mode pick one, so
    // the dot never lands where the inline bars go.
    property bool shown: true
    visible: root.shown && RecordingService.recording

    SequentialAnimation on opacity {
        running: root.visible
        loops: Animation.Infinite
        NumberAnimation {
            from: 1
            to: 0.2
            duration: 600
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            from: 0.2
            to: 1
            duration: 600
            easing.type: Easing.InOutQuad
        }
    }
}
