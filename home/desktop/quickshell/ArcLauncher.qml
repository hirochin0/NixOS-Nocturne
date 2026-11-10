import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    screen: Quickshell.screens[0] ?? null
    anchors { left: true; top: true }
    margins { left: 20; top: 60 }
    implicitWidth: Math.min(card.implicitWidth, screen ? screen.width - 40 : 790)
    implicitHeight: Math.min(card.implicitHeight, screen ? screen.height - 100 : 590)
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
        Region { item: card.opened && card.pages > 1 ? card.pageControls : null }
    }
    ArcLauncherCard { id: card; anchors.fill: parent }
}
