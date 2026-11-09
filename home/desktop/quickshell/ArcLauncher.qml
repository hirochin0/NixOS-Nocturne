import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    screen: Quickshell.screens[0] ?? null
    anchors { left: true; top: true }
    margins { left: 20; top: 60 }
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "nocturne-launcher"
    WlrLayershell.keyboardFocus: card.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    ArcLauncherCard { id: card; anchors.fill: parent }
}
