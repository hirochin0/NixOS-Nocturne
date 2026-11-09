import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.UPower
import "BatteryLogic.js" as BatteryLogic

Rectangle {
    id: card
    signal closeRequested()
    signal profileRequested(int profile)
    signal percentageRequested(bool value)
    property var device: null
    property bool onBattery: false
    property int activeProfile: PowerProfile.Balanced
    property bool hasPerformanceProfile: false
    property bool performanceLimited: false
    property bool showPercentage: true
    property bool preferenceBusy: false
    readonly property bool ready: !!device && device.ready
    readonly property bool present: ready && device.isPresent
    readonly property string percentageText: BatteryLogic.percentage(ready ? device.percentage : NaN, ready, present)
    readonly property string estimateText: BatteryLogic.estimate(ready, present,
        onBattery || (ready && device.state === UPowerDeviceState.Discharging),
        ready && device.state === UPowerDeviceState.Charging,
        ready && device.state === UPowerDeviceState.FullyCharged,
        ready ? device.timeToEmpty : 0, ready ? device.timeToFull : 0)
    implicitWidth: 360
    implicitHeight: content.implicitHeight + 36
    color: Qt.alpha(Theme.bg, 0.98)
    radius: 18
    border.width: 1
    border.color: Qt.alpha(Theme.cyan, 0.5)

    MouseArea { anchors.fill: parent } // absorb clicks inside the card
    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Text { text: "BATTERY"; color: Theme.cyan; font.family: Theme.font; font.pixelSize: 13; Layout.fillWidth: true }
            ActionButton { text: "󰅖"; hint: "Close"; onClicked: card.closeRequested() }
        }
        Text { text: card.percentageText; color: Theme.text; font.family: Theme.font; font.pixelSize: 34 }
        Text { text: card.estimateText; color: Theme.muted; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        Repeater {
            model: [
                { label: "Save", profile: PowerProfile.PowerSaver, icon: "󰌪" },
                { label: "Balanced", profile: PowerProfile.Balanced, icon: "󰾅" },
                { label: "Power", profile: PowerProfile.Performance, icon: "󰓅" }
            ]
            delegate: Button {
                id: option
                required property var modelData
                readonly property bool selected: card.activeProfile === modelData.profile
                Layout.fillWidth: true
                implicitHeight: 46
                enabled: modelData.profile !== PowerProfile.Performance || card.hasPerformanceProfile
                hoverEnabled: true
                opacity: enabled ? 1 : 0.4
                Accessible.name: modelData.label
                onClicked: card.profileRequested(modelData.profile)
                background: Rectangle {
                    radius: 12
                    color: option.selected ? Qt.alpha(Theme.cyan, 0.15) : (option.hovered ? Theme.elevated : Theme.surface)
                    border.width: option.selected ? 1 : 0
                    border.color: Theme.cyan
                }
                contentItem: RowLayout {
                    spacing: 12
                    Text { text: option.modelData.icon; color: Theme.cyan; font.family: Theme.font; font.pixelSize: 22; Layout.leftMargin: 10 }
                    Text { text: option.modelData.label; color: Theme.text; font.family: Theme.font; font.pixelSize: 14; Layout.fillWidth: true }
                    Text { text: option.selected ? "󰄬" : ""; color: Theme.cyan; font.family: Theme.font; font.pixelSize: 20; Layout.rightMargin: 10 }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Show percentage in bar"; color: Theme.text; font.pixelSize: 12; Layout.fillWidth: true }
            Switch {
                objectName: "batteryPercentageSwitch"
                checked: card.showPercentage
                enabled: !card.preferenceBusy
                Accessible.name: "Show battery percentage in bar"
                onClicked: card.percentageRequested(checked)
            }
        }
        Text {
            visible: card.performanceLimited
            Layout.fillWidth: true
            text: "Performance limited"
            color: Theme.yellow
            font.pixelSize: 11
        }
    }
}
