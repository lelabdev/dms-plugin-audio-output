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

    // --- Helpers ---
    function sinkIcon() {
        return isUsb ? "headset" : "speaker";
    }

    function cycleOutput() {
        var name = AudioService.cycleAudioOutput();
        if (name) {
            ToastService.info(name);
        }
    }

    // --- Bar pill (horizontal) ---
    horizontalBarPill: Rectangle {
        width: iconH.size + Theme.spacingS * 2
        height: width
        radius: width / 2
        color: hMouse.containsMouse
            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
            : "transparent"

        DankIcon {
            id: iconH
            anchors.centerIn: parent
            name: sinkIcon()
            size: Theme.barIconSize(root.barThickness, -4)
            color: Theme.primary
        }

        MouseArea {
            id: hMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.cycleOutput()
        }
    }

    // --- Bar pill (vertical) ---
    verticalBarPill: Rectangle {
        width: iconV.size + Theme.spacingS * 2
        height: width
        radius: width / 2
        color: vMouse.containsMouse
            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
            : "transparent"

        DankIcon {
            id: iconV
            anchors.centerIn: parent
            name: sinkIcon()
            size: Theme.barIconSize(root.barThickness, -4)
            color: Theme.primary
        }

        MouseArea {
            id: vMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.cycleOutput()
        }
    }
}
