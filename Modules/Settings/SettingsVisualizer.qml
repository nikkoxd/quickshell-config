import QtQuick
import QtQuick.Layouts
import qs.Core

ColumnLayout {
    id: root
    spacing: 10
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop

    readonly property bool bars: SettingsDraft.get("visualizer", "mode") === "bars"

    SettingsOption {
        title: "Display visualizer"
        value: SettingsDraft.get("visualizer", "displayVisualizer")
        onChecked: value => SettingsDraft.set("visualizer", "displayVisualizer", value)
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Display artwork"
        value: SettingsDraft.get("visualizer", "displayArtwork")
        onChecked: value => SettingsDraft.set("visualizer", "displayArtwork", value)
        type: SettingsOption.Type.Switch
    }

    SettingsOption {
        title: "Mode"
        value: SettingsDraft.get("visualizer", "mode")
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
        onEdited: value => SettingsDraft.set("visualizer", "mode", value)
        type: SettingsOption.Type.ComboBox
    }

    SettingsOption {
        title: "Audio source"
        value: SettingsDraft.get("visualizer", "source")
        options: [
            {
                label: "All audio",
                value: "auto"
            },
            {
                label: "Media player",
                value: "player"
            }
        ]
        onEdited: value => SettingsDraft.set("visualizer", "source", value)
        type: SettingsOption.Type.ComboBox
    }

    SettingsOption {
        title: "Visualizer height"
        units: "px"
        visible: !root.bars
        value: SettingsDraft.get("visualizer", "visualizerHeight")
        onEdited: value => SettingsDraft.set("visualizer", "visualizerHeight", parseInt(value))
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Top opacity"
        maximum: 100
        units: "%"
        visible: !root.bars
        value: SettingsDraft.get("visualizer", "topOpacity") * 100
        onEdited: value => SettingsDraft.set("visualizer", "topOpacity", parseInt(value) / 100)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Bottom opacity"
        maximum: 100
        units: "%"
        visible: !root.bars
        value: SettingsDraft.get("visualizer", "bottomOpacity") * 100
        onEdited: value => SettingsDraft.set("visualizer", "bottomOpacity", parseInt(value) / 100)
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Bar count"
        visible: root.bars
        value: SettingsDraft.get("visualizer", "barCount")
        onEdited: value => SettingsDraft.set("visualizer", "barCount", parseInt(value))
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Bar width"
        units: "px"
        visible: root.bars
        value: SettingsDraft.get("visualizer", "barWidth")
        onEdited: value => SettingsDraft.set("visualizer", "barWidth", parseInt(value))
        type: SettingsOption.Type.TextField
    }

    SettingsOption {
        title: "Bar height"
        units: "px"
        visible: root.bars
        value: SettingsDraft.get("visualizer", "barMaxHeight")
        onEdited: value => SettingsDraft.set("visualizer", "barMaxHeight", parseInt(value))
        type: SettingsOption.Type.TextField
    }
}
