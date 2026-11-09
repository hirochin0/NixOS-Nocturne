import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower

PanelWindow {
    id: menu
    signal dismissed()
    property bool showPercentage: true
    visible: false
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nocturne-power-menu"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    onVisibleChanged: if (visible && !preferenceReader.running) preferenceReader.running = true

    Process {
        id: preferenceReader
        command: [Theme.batteryCommand, "get-percentage"]
        stdout: StdioCollector {
            onStreamFinished: {
                var value = this.text.trim();
                if (value === "true" || value === "false") menu.showPercentage = value === "true";
            }
        }
    }
    Process {
        id: preferenceWriter
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) console.warn("Could not save battery percentage preference");
            if (!preferenceReader.running) preferenceReader.running = true;
        }
    }

    MouseArea { anchors.fill: parent; onClicked: menu.dismissed() }
    Item {
        anchors.fill: parent
        focus: menu.visible
        Keys.onEscapePressed: menu.dismissed()
        PowerCard {
            anchors { top: parent.top; right: parent.right; topMargin: 64; rightMargin: 24 }
            width: Math.min(360, parent.width - 32)
            height: implicitHeight
            device: UPower.displayDevice
            onBattery: UPower.onBattery
            activeProfile: PowerProfiles.profile
            hasPerformanceProfile: PowerProfiles.hasPerformanceProfile
            performanceLimited: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
            showPercentage: menu.showPercentage
            preferenceBusy: preferenceWriter.running
            onCloseRequested: menu.dismissed()
            onProfileRequested: profile => PowerProfiles.profile = profile
            onPercentageRequested: value => {
                if (preferenceWriter.running) return;
                menu.showPercentage = value;
                preferenceWriter.command = [Theme.batteryCommand, "set-percentage", value ? "true" : "false"];
                preferenceWriter.running = true;
            }
        }
    }
}
