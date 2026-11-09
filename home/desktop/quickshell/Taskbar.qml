import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar
    signal powerRequested()
    anchors { top: true; left: true; right: true }
    margins { top: 10; left: 14; right: 14 }
    implicitHeight: 46
    exclusionMode: ExclusionMode.Auto
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "nocturne-taskbar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    BarContent { anchors.fill: parent; hostWindow: bar; onPowerRequested: bar.powerRequested() }
}
