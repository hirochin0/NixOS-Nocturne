import QtQuick
import QtQuick.Controls

Button {
    id: control
    property string hint: ""
    property color tint: Theme.text
    signal secondaryClicked()
    signal scrolled(bool up)
    implicitWidth: label.implicitWidth + 16
    implicitHeight: 32
    hoverEnabled: true
    padding: 8
    Accessible.name: hint || text
    contentItem: Text {
        id: label
        text: control.text
        color: control.tint
        font { family: Theme.font; pixelSize: 12 }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: 9
        color: control.down ? Qt.alpha(Theme.cyan, 0.2) : control.hovered ? Theme.elevated : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: control.secondaryClicked()
        onWheel: wheel => { control.scrolled(wheel.angleDelta.y > 0); wheel.accepted = true; }
    }
    ToolTip.visible: hovered && hint.length > 0
    ToolTip.text: hint
    ToolTip.delay: 350
}
