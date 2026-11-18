import QtQuick
import Quickshell.Widgets

Item {
    id: water
    property alias contentItem: face.contentItem
    property real roundness: 12
    property real cursorX: width * 0.65
    property real cursorY: height * 0.25
    property real tension: 0
    property real entrance: 1
    property real ripple: 0
    Behavior on cursorX { SmoothedAnimation { duration: 100; velocity: -1 } }
    Behavior on cursorY { SmoothedAnimation { duration: 100; velocity: -1 } }
    Behavior on tension { SpringAnimation { spring: 3; damping: 0.3; mass: 0.8 } }
    function appear() { entrance = 0; openAnimation.restart(); wave.restart(); }
    function disappear() { openAnimation.stop(); wave.stop(); tension = 0; ripple = 0; }
    NumberAnimation { id: openAnimation; target: water; property: "entrance"; from: 0; to: 1; duration: 450; easing.type: Easing.OutElastic; easing.amplitude: 0.6; easing.period: 0.5 }
    SequentialAnimation {
        id: wave
        NumberAnimation { target: water; property: "ripple"; from: 0; to: 0.6; duration: 100; easing.type: Easing.OutCubic }
        NumberAnimation { target: water; property: "ripple"; to: -0.18; duration: 130; easing.type: Easing.InOutSine }
        NumberAnimation { target: water; property: "ripple"; to: 0; duration: 270; easing.type: Easing.OutCubic }
    }
    // Render the captured buffer directly. Offscreen texture effects stay on the
    // decorative board, never on the native screencopy node.
    ClippingRectangle {
        id: face
        anchors.fill: parent
        radius: water.roundness
        color: "#181f2c"
        border.width: 1
        border.color: "#80d7efff"
        transform: [
            Translate { x: (water.cursorX - water.width / 2) * water.tension * 0.025; y: (water.cursorY - water.height / 2) * water.tension * 0.025 },
            Scale {
                origin.x: water.width / 2; origin.y: 0
                xScale: 0.97 + water.entrance * 0.03 + water.ripple * 0.009
                yScale: 0.88 + water.entrance * 0.12 - water.ripple * 0.012
            }
        ]
    }
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
        height: Math.min(32, parent.height * 0.12)
        radius: water.roundness
        gradient: Gradient {
            GradientStop { position: 0; color: "#22ffffff" }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
