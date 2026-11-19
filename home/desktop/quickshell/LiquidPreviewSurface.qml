import QtQuick

Item {
    id: water
    property alias contentItem: content
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
    Item {
        id: face
        anchors.fill: parent
        clip: true
        Rectangle { anchors.fill: parent; color: "#181f2c" }
        Item { id: content; anchors.fill: parent; anchors.margins: 1 }
        // No layer, ShaderEffectSource, or ClippingRectangle here: the native
        // screencopy node must render in the popup's own scene graph.
        transform: [
            Translate { x: (water.cursorX - water.width / 2) * water.tension * 0.025; y: (water.cursorY - water.height / 2) * water.tension * 0.025 },
            Scale {
                origin.x: water.width / 2; origin.y: 0
                xScale: 0.97 + water.entrance * 0.03 + water.ripple * 0.009
                yScale: 0.88 + water.entrance * 0.12 - water.ripple * 0.012
            }
        ]
        // Cover only the four corners. These decorations never sample or
        // redirect the captured image into a render texture.
        Canvas {
            id: corners
            z: 10
            anchors.fill: parent
            property real radius: Math.min(water.roundness, width / 2, height / 2)
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onRadiusChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = "#1b293b";
                for (let i = 0; i < 4; ++i) {
                    ctx.save();
                    ctx.translate(i % 2 ? width : 0, i >= 2 ? height : 0);
                    ctx.scale(i % 2 ? -1 : 1, i >= 2 ? -1 : 1);
                    ctx.beginPath();
                    ctx.moveTo(0, 0);
                    ctx.lineTo(radius, 0);
                    ctx.arcTo(0, 0, 0, radius, radius);
                    ctx.closePath();
                    ctx.fill();
                    ctx.restore();
                }
            }
        }
        Rectangle {
            z: 11
            anchors.fill: parent
            radius: water.roundness
            color: "transparent"
            border.width: 1
            border.color: "#80d7efff"
        }
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
