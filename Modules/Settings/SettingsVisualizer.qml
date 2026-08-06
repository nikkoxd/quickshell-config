import QtQuick
import QtQuick.Layouts
import qs.Core

ColumnLayout {
    spacing: 10
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

    SettingsOption {
        title: "Display visualizer"
        value: Config.visualizer.displayVisualizer
        onChecked: value => Config.visualizer.displayVisualizer = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Visualizer height"
        units: "px"
        value: Config.visualizer.visualizerHeight
        onEdited: value => Config.visualizer.visualizerHeight = parseInt(value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Top opacity"
        units: "%"
        value: Config.visualizer.topOpacity * 100
        onEdited: value => Config.visualizer.topOpacity = parseInt(value) / 100
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Bottom opacity"
        units: "%"
        value: Config.visualizer.bottomOpacity * 100
        onEdited: value => Config.visualizer.bottomOpacity = parseInt(value) / 100
        type: SettingsOption.Type.TextField
    }
}
