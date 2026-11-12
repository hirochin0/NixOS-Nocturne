import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    anchors { right: true; bottom: true }
    margins { right: 24; bottom: 24 }
    implicitWidth: 240
    implicitHeight: 135
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "nocturne-dino"
    // OnDemand lets the compositor focus this surface on the initial click.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    DinoGame {
        anchors.fill: parent
        bestScore: DinoScores.bestScore
        onRecordRequested: value => DinoScores.record(value)
    }
}
