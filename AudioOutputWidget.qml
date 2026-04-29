import QtQuick
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

    // --- Helpers ---
    function sinkIcon() {
        if (!currentSink?.audio || currentSink.audio.muted) return "volume_off";
        if (volumePercent === 0) return "volume_mute";
        if (volumePercent <= 33) return "volume_down";
        return isUsb ? "headset" : "speaker";
    }

    function cycleOutput() {
        var name = AudioService.cycleAudioOutput();
        if (name) {
            ToastService.info(name);
        }
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

    // --- Click to cycle output, wheel to change volume ---
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: root.cycleOutput()
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                root.changeVolume(AudioService.volumeStep ?? 5);
            } else if (wheel.angleDelta.y < 0) {
                root.changeVolume(-(AudioService.volumeStep ?? 5));
            }
        }
    }
}
