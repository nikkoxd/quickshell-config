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
    property bool closeOnUnhover: false

    // How far the island has to slide sideways for this view to read as
    // centred. A view whose content is laid out asymmetrically (the default
    // view, whose flanks fill independently) sets it so the thing that should
    // sit in the middle of the screen actually does; shell.qml offsets the
    // window by it.
    property real centreOffset: 0

    Shortcut {
        sequence: "Escape"
        onActivated: root.closeRequested()
    }

    /* legacy stuff */
    signal closeRequested()
    signal viewChangeRequested(view: string)
}
