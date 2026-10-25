import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // --- State ---
    property var currentSink: AudioService.sink
    property int volumePercent: {
        const volume = currentSink?.audio?.volume;
        if (!Number.isFinite(volume))
            return 0;
        return Math.min(AudioService.getMaxVolumePercent(currentSink), Math.round(volume * 100));
    }
    readonly property string volumeLabel: Number.isFinite(currentSink?.audio?.volume) ? `${volumePercent}%` : "--"

    // Names of outputs excluded from cycling. Stored by PipeWire node name so the
    // preference survives reconnects and list reordering.
    readonly property string excludedOutputsKey: "excludedOutputs"
    property var excludedOutputs: Array.isArray(pluginData.excludedOutputs) ? pluginData.excludedOutputs : []

    readonly property var connectedOutputs: AudioService.allNodes.filter(node => node && node.name && node.audio && node.isSink && !node.isStream)

    readonly property var displayOutputs: {
        const outputs = connectedOutputs.slice();
        outputs.sort((a, b) => root.outputName(a).localeCompare(root.outputName(b)));
        return outputs;
    }

    // --- Helpers ---
    function sinkIcon() {
        if (!currentSink?.audio) return "volume_off";
        if (currentSink.audio.muted) return "volume_off";
        if (currentSink.audio.volume === 0) return "volume_mute";
        return AudioService.sinkIcon(currentSink);
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

        const currentName = AudioService.sink?.name ?? "";
        const currentIndex = enabled.findIndex(node => node.name === currentName);
        const nextIndex = currentIndex === -1 ? 0 : (currentIndex + 1) % enabled.length;
        const nextSink = enabled[nextIndex];

        if (!nextSink || nextSink.name === currentName)
            return;

        if (AudioService.setDefaultSinkByName(nextSink.name))
            ToastService.showInfo(outputName(nextSink));
    }

    function adjustVolume(direction) {
        if (!AudioService.sink?.audio)
            return;
        AudioService.adjustDefaultSinkVolume(AudioService.wheelVolumeStep, direction);
        AudioService.playVolumeChangeSoundIfEnabled();
    }

    function cycleOutputAction() {
        root.cycleOutput();
    }

    // triggerPopout() prefers pillClickAction when it is set, so clear it
    // briefly to open the selection panel from the right-click action.
    property var leftClickAction: root.cycleOutputAction

    function openOutputPanel() {
        const leftAction = root.leftClickAction;
        root.leftClickAction = null;
        try {
            root.triggerPopout();
        } finally {
            root.leftClickAction = leftAction;
        }
    }

    pillClickAction: root.leftClickAction
    pillRightClickAction: () => root.openOutputPanel()

    // --- Bar pill (horizontal) ---
    horizontalBarPill: Row {
        spacing: Theme.spacingXS

        DIcon {
            name: root.sinkIcon()
            size: root.iconSize
            color: Theme.widgetIconColor
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: root.volumeLabel
            font.pixelSize: root.textSize
            color: Theme.widgetTextColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // --- Bar pill (vertical) ---
    verticalBarPill: Column {
        spacing: Theme.spacingXXS

        DIcon {
            name: root.sinkIcon()
            size: root.iconSize
            color: Theme.widgetIconColor
            anchors.horizontalCenter: parent.horizontalCenter
        }

        StyledText {
            text: root.volumeLabel
            font.pixelSize: root.textSize
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

                        DRipple {
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

                            DIcon {
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

    // Keep backend device lists current while this widget is alive.
    Component.onCompleted: AudioService.addRef()
    Component.onDestruction: AudioService.removeRef()

    // Volume wheel, without a MouseArea overlaying the bar pill.
    WheelHandler {
        onWheel: event => {
            const direction = event.angleDelta.y > 0 ? 1 : (event.angleDelta.y < 0 ? -1 : 0);
            if (direction === 0)
                return;
            root.adjustVolume(direction);
            event.accepted = true;
        }
    }
}
