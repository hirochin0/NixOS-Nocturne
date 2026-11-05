import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower

PanelWindow {
    id: menu
    signal dismissed()
    visible: false
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nocturne-power-menu"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    MouseArea { anchors.fill: parent; onClicked: menu.dismissed() }
    Item {
        anchors.fill: parent
        focus: menu.visible
        Keys.onEscapePressed: menu.dismissed()
        Rectangle {
            id: panel
            anchors { top: parent.top; right: parent.right; topMargin: 64; rightMargin: 24 }
            width: Math.min(360, parent.width - 32)
            height: content.implicitHeight + 36
            color: Qt.alpha(Theme.bg, 0.98)
            radius: 18
            border.width: 1
            border.color: Qt.alpha(Theme.cyan, 0.5)
            MouseArea { anchors.fill: parent } // absorb clicks inside the card
            ColumnLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                spacing: 10
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "POWER MODE"; color: Theme.cyan; font.family: Theme.font; font.pixelSize: 13; Layout.fillWidth: true }
                    ActionButton { text: "󰅖"; hint: "Close"; onClicked: menu.dismissed() }
                }
                Repeater {
                    model: [
                        { label: "Save", detail: "バッテリー優先・省電力", profile: PowerProfile.PowerSaver, icon: "󰌪" },
                        { label: "Balanced", detail: "性能と消費電力のバランス", profile: PowerProfile.Balanced, icon: "󰾅" },
                        { label: "Power", detail: "性能優先・消費電力は増加", profile: PowerProfile.Performance, icon: "󰓅" }
                    ]
                    delegate: Button {
                        id: option
                        required property var modelData
                        readonly property bool selected: PowerProfiles.profile === modelData.profile
                        Layout.fillWidth: true
                        implicitHeight: 62
                        enabled: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                        hoverEnabled: true
                        opacity: enabled ? 1 : 0.4
                        Accessible.name: modelData.label
                        onClicked: PowerProfiles.profile = modelData.profile
                        background: Rectangle {
                            radius: 12
                            color: option.selected ? Qt.alpha(Theme.cyan, 0.15) : (option.hovered ? Theme.elevated : Theme.surface)
                            border.width: option.selected ? 1 : 0
                            border.color: Theme.cyan
                        }
                        contentItem: RowLayout {
                            spacing: 12
                            Text { text: option.modelData.icon; color: Theme.cyan; font.family: Theme.font; font.pixelSize: 22; Layout.leftMargin: 10 }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Text { text: option.modelData.label; color: Theme.text; font.family: Theme.font; font.pixelSize: 14; font.bold: true }
                                Text { text: option.enabled ? option.modelData.detail : "この機器では利用できません"; color: Theme.muted; font.pixelSize: 11 }
                            }
                            Text { text: option.selected ? "󰄬" : ""; color: Theme.cyan; font.family: Theme.font; font.pixelSize: 20; Layout.rightMargin: 10 }
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
                        ? "温度などにより性能が制限されています。" : "選択は即座に反映されます。Escで閉じる"
                    wrapMode: Text.WordWrap
                    color: Theme.muted
                    font.pixelSize: 11
                }
            }
        }
    }
}
