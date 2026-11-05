import QtQuick
import QtQuick.Controls

Button {
    id: control
    property bool accent: false
    property bool active: false
    property string hint: ""
    implicitWidth: accent ? 46 : 34
    implicitHeight: accent ? 46 : 34
    hoverEnabled: true
    opacity: enabled ? 1 : 0.3
    font.family: Theme.font
    font.pixelSize: accent ? 22 : 18
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.accent ? Theme.bg : (control.active ? Theme.cyan : Theme.text)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: width / 2
        color: control.accent ? Theme.cyan : (control.hovered ? Theme.elevated : "transparent")
        opacity: control.down ? 0.75 : 1
    }
    ToolTip.visible: hovered && hint.length > 0
    ToolTip.text: hint
    Accessible.name: hint
}
