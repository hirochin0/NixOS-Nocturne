import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    anchors { right: true; bottom: true }
    margins { right: 24; bottom: 24 }
    implicitWidth: 360
    implicitHeight: 203
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "nocturne-dino"
    // OnDemand lets the compositor focus this surface on the initial click.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    DinoGame {
        width: 240; height: 135
        scale: Math.min(parent.width / width, parent.height / height)
        transformOrigin: Item.TopLeft
        bestScore: DinoScores.bestScore
        onRecordRequested: value => DinoScores.record(value)
    }
}
