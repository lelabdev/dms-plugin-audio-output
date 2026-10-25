import QtQuick
import Quickshell.Services.Pipewire
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // --- State ---
    property var currentSink: AudioService.sink
    property bool isUsb: currentSink?.name?.includes("usb") ?? false
    property int volumePercent: currentSink?.audio ? Math.round(currentSink.audio.volume * 100) : 0

    // Names of outputs excluded from cycling. Stored by PipeWire node name so the
    // preference survives reconnects and list reordering.
    readonly property string excludedOutputsKey: "excludedOutputs"
    property var excludedOutputs: Array.isArray(pluginData.excludedOutputs) ? pluginData.excludedOutputs : []

    // Use AudioService's backend-agnostic node list when available, and fall
    // back to PipeWire directly on older DMS versions.
    readonly property var connectedOutputs: {
        const nodes = AudioService.allNodes || Pipewire.nodes.values || [];
        return nodes.filter(node => node && node.name && node.audio && node.isSink && !node.isStream);
    }

    readonly property var displayOutputs: {
        const outputs = connectedOutputs.slice();
        outputs.sort((a, b) => root.outputName(a).localeCompare(root.outputName(b)));
        return outputs;
    }

    // --- Helpers ---
    function sinkIcon() {
        if (!currentSink?.audio || currentSink.audio.muted) return "volume_off";
        if (volumePercent === 0) return "volume_mute";
        if (volumePercent <= 33) return "volume_down";
        return isUsb ? "headset" : "speaker";
    }

    function outputName(node) {
        const name = AudioService.displayName(node);
        return name && name.length > 0 ? name : (node?.name ?? "");
    }

    function isExcluded(nodeName) {
        return !!nodeName && excludedOutputs.indexOf(nodeName) !== -1;
    }

    function hoverTint(base) {
        const factor = 1.2;
        return Theme.isLightMode ? Qt.darker(base, factor) : Qt.lighter(base, factor);
    }

    function saveExcludedOutputs(names) {
        const unique = [];
        for (const name of names) {
            if (name && unique.indexOf(name) === -1)
                unique.push(name);
        }

        if (pluginService) {
            pluginService.savePluginData(pluginId || "audioOutputToggle", excludedOutputsKey, unique);
            return;
        }

        excludedOutputs = unique;
        SettingsData.setPluginSetting(pluginId || "audioOutputToggle", excludedOutputsKey, unique);
    }

    function toggleOutput(nodeName) {
        if (!nodeName) return;

        const updated = excludedOutputs.slice();
        const index = updated.indexOf(nodeName);
        if (index === -1)
            updated.push(nodeName);
        else
            updated.splice(index, 1);

        saveExcludedOutputs(updated);
    }

    function cycleOutput() {
        const enabled = connectedOutputs.filter(node => !isExcluded(node.name));

        if (enabled.length === 0) {
            ToastService.showInfo(connectedOutputs.length === 0
                ? "No audio outputs connected"
                : "All outputs are excluded. Right-click to enable one.");
            return;
        }

        const currentName = currentSink?.name ?? "";
        const currentIndex = enabled.findIndex(node => node.name === currentName);
        const nextIndex = currentIndex === -1 ? 0 : (currentIndex + 1) % enabled.length;
        const nextSink = enabled[nextIndex];

        if (!nextSink || nextSink.name === currentName)
            return;

        if (AudioService.setDefaultSinkByName(nextSink.name))
            ToastService.showInfo(outputName(nextSink));
    }

    function changeVolume(delta) {
        if (!currentSink?.audio) return;
        currentSink.audio.muted = false;
        var newVol = Math.max(0, Math.min(AudioService.sinkMaxVolume / 100, currentSink.audio.volume + delta / 100));
        currentSink.audio.volume = newVol;
        AudioService.playVolumeChangeSoundIfEnabled();
    }

    // --- Bar pill (horizontal) ---
    horizontalBarPill: Row {
        spacing: Theme.spacingXS

        DankIcon {
            name: sinkIcon()
            size: Theme.barIconSize(root.barThickness, -4)
            color: Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: `${volumePercent}%`
            font.pixelSize: Theme.barTextSize(root.barThickness)
            color: Theme.widgetTextColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // --- Bar pill (vertical) ---
    verticalBarPill: Column {
        spacing: 1

        DankIcon {
            name: sinkIcon()
            size: Theme.barIconSize(root.barThickness, -4)
            color: Theme.primary
            anchors.horizontalCenter: parent.horizontalCenter
        }

        StyledText {
            text: `${volumePercent}%`
            font.pixelSize: Theme.barTextSize(root.barThickness)
            color: Theme.widgetTextColor
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    popoutWidth: 340

    // --- Output inclusion panel ---
    popoutContent: Component {
        PopoutComponent {
            headerText: "Audio outputs"
            detailsText: "Click a device to include or exclude it from cycling."
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingXS

                Repeater {
                    model: root.displayOutputs

                    delegate: Rectangle {
                        id: outputCard
                        required property var modelData

                        readonly property bool included: !root.isExcluded(modelData.name)

                        width: parent.width
                        height: 52
                        radius: Theme.cornerRadius
                        color: {
                            if (outputCard.included)
                                return outputMouseArea.containsMouse ? root.hoverTint(Theme.ccTileActiveBg) : Theme.ccTileActiveBg;
                            return outputMouseArea.containsMouse ? Theme.primaryHoverLight : Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency);
                        }
                        border.width: outputCard.included ? 0 : 1
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)

                        DankRipple {
                            id: cardRipple
                            cornerRadius: outputCard.radius
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingS

                            DankIcon {
                                name: AudioService.sinkIcon(outputCard.modelData)
                                size: Theme.iconSize
                                color: outputCard.included ? Theme.ccTileActiveText : Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                width: parent.width - Theme.iconSize - parent.spacing
                                text: root.outputName(outputCard.modelData)
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: outputCard.included ? Font.Medium : Font.Normal
                                color: outputCard.included ? Theme.ccTileActiveText : Theme.surfaceText
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: outputMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: mouse => cardRipple.trigger(mouse.x, mouse.y)
                            onClicked: root.toggleOutput(outputCard.modelData.name)
                        }
                    }
                }

                StyledText {
                    width: parent.width
                    visible: root.displayOutputs.length === 0
                    text: "No audio outputs connected"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                }
            }
        }
    }

    // --- Click to cycle output, right-click for the inclusion panel, wheel to change volume ---
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.triggerPopout();
            else
                root.cycleOutput();
        }
        onWheel: wheel => {
            const step = AudioService.wheelVolumeStep ?? AudioService.volumeStep ?? 5;
            if (wheel.angleDelta.y > 0) {
                root.changeVolume(step);
            } else if (wheel.angleDelta.y < 0) {
                root.changeVolume(-step);
            }
        }
    }
}
