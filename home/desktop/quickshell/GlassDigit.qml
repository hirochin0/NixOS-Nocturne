import QtQuick
import QtQuick.Effects

Item {
    id: digit
    property Item glassSource: null
    property string text: "0"
    property real fontSize: 200
    property real pointerX: 0
    property real pointerY: 0
    property real pullX: 0
    property real pullY: 0
    property real tension: 0
    // Transparent border leaves room for the deformed contour without changing layout.
    readonly property real surfacePadding: 24
    readonly property real surfaceWidth: width + surfacePadding * 2
    readonly property real surfaceHeight: height + surfacePadding * 2
    property real surfaceX: pointerX + surfacePadding
    property real surfaceY: pointerY + surfacePadding
    Behavior on surfaceX { SmoothedAnimation { duration: 110; velocity: -1 } }
    Behavior on surfaceY { SmoothedAnimation { duration: 110; velocity: -1 } }
    readonly property bool software: GraphicsInfo.api === GraphicsInfo.Software
    implicitWidth: fontSize * (text === ":" ? 0.26 : 0.65)
    implicitHeight: fontSize * 1.35
    Behavior on pullX { SpringAnimation { spring: 3.4; damping: 0.25; mass: 0.7 } }
    Behavior on pullY { SpringAnimation { spring: 3.4; damping: 0.25; mass: 0.7 } }
    Behavior on tension { SpringAnimation { spring: 3; damping: 0.24 } }
    Item {
        id: liquid
        x: -digit.surfacePadding
        y: -digit.surfacePadding
        width: digit.surfaceWidth
        height: digit.surfaceHeight
        layer.enabled: !digit.software
        layer.smooth: true
        layer.effect: ShaderEffect {
            property vector2d cursorPosition: Qt.vector2d(digit.surfaceX, digit.surfaceY)
            property real strength: digit.tension
            property real radius: digit.fontSize * 0.24
            mesh: Qt.size(40, 56)
            vertexShader: "droplet.vert.qsb"
        }
        Text {
            id: glyph
            anchors.fill: parent
            text: digit.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font { family: Theme.roundFont; pixelSize: digit.fontSize; weight: Font.Black; variableAxes: ({"wght": 900}); letterSpacing: -3 }
            color: "white"
            visible: false
            layer.enabled: true
        }
        Text {
            anchors.fill: parent
            text: glyph.text; font: glyph.font
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            color: digit.software ? "#dcecf3" : Qt.alpha("#b6eaff", 0.12)
            style: Text.Outline
            styleColor: Qt.alpha("white", 0.38)
        }
        MultiEffect {
            anchors.fill: parent
            source: digit.glassSource
            visible: !digit.software && !!digit.glassSource
            maskEnabled: true
            maskSource: glyph
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 0.18
            blurMax: 16
            brightness: 0.12
            saturation: -0.2
            opacity: 0.75
        }
        Rectangle {
            anchors.fill: parent
            visible: !digit.software
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha("#f4fdff", 0.72) }
                GradientStop { position: 0.3; color: Qt.alpha("white", 0.48) }
                GradientStop { position: 0.49 + digit.tension * 0.06; color: Qt.alpha("#b8e8ff", 0.10) }
                GradientStop { position: 0.55 + digit.tension * 0.06; color: Qt.alpha("white", 0.35) }
                GradientStop { position: 1; color: Qt.alpha("#b4d5f2", 0.20) }
            }
            layer.enabled: true
            layer.effect: MultiEffect { maskEnabled: true; maskSource: glyph }
        }
        Text {
            anchors.fill: parent
            anchors.topMargin: -1
            text: glyph.text; font: glyph.font
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            color: "transparent"
            style: Text.Outline
            styleColor: Qt.alpha("white", 0.18 + digit.tension * 0.25)
        }
    }
}
