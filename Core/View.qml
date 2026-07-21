import QtQuick

FocusScope {
    id: root
    signal pop()
    signal push(view: string)
    signal replace(view: string)
    property bool dismissable: true
    property bool focused: false
    property var popups: []
    property bool displayInFullscreen: false

    Shortcut {
        sequence: "Escape"
        onActivated: root.closeRequested()
    }

    /* legacy stuff */
    signal closeRequested()
    signal viewChangeRequested(view: string)
    signal defaultViewChangeRequested(view: string)
}
