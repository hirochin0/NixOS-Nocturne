import QtQuick
import QtQuick.Controls

Button {
    id: control
    property int labelSize: 13
    property string labelFont: Theme.roundFont
    property int labelWeight: Font.Bold
    property string hint: ""
    property color tint: Theme.text
    signal secondaryClicked()
    signal scrolled(bool up)
    implicitWidth: label.implicitWidth + 16
    implicitHeight: 38
    hoverEnabled: true
    padding: 8
    Accessible.name: hint || text
    contentItem: Text {
        id: label
        text: control.text
        color: control.tint
        font { family: control.labelFont; pixelSize: control.labelSize; weight: control.labelWeight; variableAxes: ({"wght": control.labelWeight === Font.Normal ? 400 : 800}) }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: height / 2
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
