import QtQuick
import QtQuick.Effects

Item {
    id: water
    property alias contentItem: face
    property real roundness: 14
    property real cursorX: width * 0.65
    property real cursorY: height * 0.25
    property real tension: 0
    property real entrance: 1
    property real ripple: 0
    readonly property bool software: GraphicsInfo.api === GraphicsInfo.Software
    Behavior on cursorX { SmoothedAnimation { duration: 100; velocity: -1 } }
    Behavior on cursorY { SmoothedAnimation { duration: 100; velocity: -1 } }
    Behavior on tension { SpringAnimation { spring: 3; damping: 0.3; mass: 0.8 } }
    function appear() { entrance = 0; openAnimation.restart(); wave.restart(); }
    function disappear() { openAnimation.stop(); wave.stop(); tension = 0; ripple = 0; }
    NumberAnimation { id: openAnimation; target: water; property: "entrance"; from: 0; to: 1; duration: 520; easing.type: Easing.OutElastic; easing.amplitude: 0.7; easing.period: 0.5 }
    SequentialAnimation {
        id: wave
        NumberAnimation { target: water; property: "ripple"; from: 0; to: 0.6; duration: 110; easing.type: Easing.OutCubic }
        NumberAnimation { target: water; property: "ripple"; to: -0.18; duration: 150; easing.type: Easing.InOutSine }
        NumberAnimation { target: water; property: "ripple"; to: 0; duration: 320; easing.type: Easing.OutCubic }
    }
    Item {
        id: droplet
        anchors.fill: parent
        transform: Scale {
            origin.x: water.width / 2; origin.y: 0
            xScale: 0.94 + water.entrance * 0.06
            yScale: 0.84 + water.entrance * 0.16
        }
        layer.enabled: !water.software
        layer.smooth: true
        layer.effect: ShaderEffect {
            property vector2d cursorPosition: Qt.vector2d(water.cursorX, water.cursorY)
            property real strength: water.ripple + water.tension
            property real radius: Math.max(40, Math.min(water.width, water.height) * 0.42)
            mesh: Qt.size(40, 32)
            vertexShader: "droplet.vert.qsb"
        }
        Rectangle {
            id: mask
            anchors.fill: parent
            radius: water.roundness
            color: "white"
            visible: false
            layer.enabled: !water.software
        }
        Item {
            id: face
            anchors.fill: parent
            clip: true
            layer.enabled: !water.software
            layer.smooth: true
            layer.effect: MultiEffect { maskEnabled: true; maskSource: mask; autoPaddingEnabled: false }
        }
        Rectangle {
            anchors.fill: parent
            radius: water.roundness
            color: "transparent"
            border.width: 1
            border.color: "#98e7f7ff"
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
            height: Math.min(66, parent.height * 0.17)
            radius: water.roundness
            gradient: Gradient {
                GradientStop { position: 0; color: "#44ffffff" }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }
}
