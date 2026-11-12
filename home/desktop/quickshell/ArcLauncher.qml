import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    anchors { left: true; top: true }
    margins { left: 20; top: 60 }
    implicitWidth: Math.min(card.implicitWidth, screen ? screen.width - 40 : 1140)
    implicitHeight: Math.min(card.implicitHeight, screen ? screen.height - 100 : 650)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "nocturne-launcher"
    WlrLayershell.keyboardFocus: card.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region {
        item: card.tileItem
        Region { item: card.opened ? card.nodeAt(0) : null }
        Region { item: card.opened ? card.nodeAt(1) : null }
        Region { item: card.opened ? card.nodeAt(2) : null }
        Region { item: card.opened ? card.nodeAt(3) : null }
        Region { item: card.opened ? card.nodeAt(4) : null }
        Region { item: card.opened ? card.nodeAt(5) : null }
        Region { item: card.opened ? card.nodeAt(6) : null }
        Region { item: card.opened ? card.nodeAt(7) : null }
        Region { item: card.opened ? card.nodeAt(8) : null }
        Region { item: card.opened ? card.nodeAt(9) : null }
        Region { item: card.opened ? card.nodeAt(10) : null }
        Region { item: card.opened ? card.nodeAt(11) : null }
        Region { item: card.opened ? card.nodeAt(12) : null }
        Region { item: card.opened ? card.nodeAt(13) : null }
        Region { item: card.opened ? card.nodeAt(14) : null }
        Region { item: card.opened ? card.nodeAt(15) : null }
        Region { item: card.opened ? card.nodeAt(16) : null }
        Region { item: card.opened ? card.nodeAt(17) : null }
        Region { item: card.opened ? card.nodeAt(18) : null }
        Region { item: card.opened ? card.nodeAt(19) : null }
        Region { item: card.opened ? card.nodeAt(20) : null }
        Region { item: card.opened && card.pages > 1 ? card.pageControls : null }
    }
    ArcLauncherCard { id: card; anchors.fill: parent }
}
