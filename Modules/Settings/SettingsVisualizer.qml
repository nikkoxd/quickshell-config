import QtQuick
import QtQuick.Layouts
import qs.Core

ColumnLayout {
    id: root
    spacing: 10
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

    readonly property bool bars: Config.visualizer.mode === "bars"

    SettingsOption {
        title: "Display visualizer"
        value: Config.visualizer.displayVisualizer
        onChecked: value => Config.visualizer.displayVisualizer = value
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Mode"
        value: Config.visualizer.mode
        options: [
            {
                label: "Background",
                value: "background"
            },
            {
                label: "Bars",
                value: "bars"
            }
        ]
        onEdited: value => Config.visualizer.mode = value
        type: SettingsOption.Type.ComboBox
    }

    SettingsOption {
        title: "Visualizer height"
        units: "px"
        visible: !root.bars
        value: Config.visualizer.visualizerHeight
        onEdited: value => Config.visualizer.visualizerHeight = parseInt(value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Top opacity"
        units: "%"
        visible: !root.bars
        value: Config.visualizer.topOpacity * 100
        onEdited: value => Config.visualizer.topOpacity = parseInt(value) / 100
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Bottom opacity"
        units: "%"
        visible: !root.bars
        value: Config.visualizer.bottomOpacity * 100
        onEdited: value => Config.visualizer.bottomOpacity = parseInt(value) / 100
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Bar count"
        visible: root.bars
        value: Config.visualizer.barCount
        onEdited: value => Config.visualizer.barCount = parseInt(value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Bar width"
        units: "px"
        visible: root.bars
        value: Config.visualizer.barWidth
        onEdited: value => Config.visualizer.barWidth = parseInt(value)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Bar height"
        units: "px"
        visible: root.bars
        value: Config.visualizer.barMaxHeight
        onEdited: value => Config.visualizer.barMaxHeight = parseInt(value)
        type: SettingsOption.Type.TextField
    }
}
