import QtQuick
import QtQuick.Effects

Item {
    id: glass
    property string text: ""
    property int maxLines: 5
    property real pixelSize: 15
    property real maxWidth: 560
    readonly property bool software: GraphicsInfo.api === GraphicsInfo.Software
    implicitWidth: Math.min(maxWidth, glyph.implicitWidth)
    implicitHeight: glyph.implicitHeight
    Text {
        id: glyph
        width: glass.width
        text: glass.text
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        maximumLineCount: glass.maxLines
        elide: Text.ElideRight
        font { family: Theme.roundFont; pixelSize: glass.pixelSize; weight: Font.Medium; variableAxes: ({"wght": 500}) }
        color: "white"
        visible: false
        layer.enabled: !glass.software
    }
    Text {
        x: 0; y: 1
        width: glass.width
        text: glyph.text; font: glyph.font; textFormat: Text.PlainText
        wrapMode: glyph.wrapMode; maximumLineCount: glyph.maximumLineCount; elide: glyph.elide
        color: "#80030c1a"
    }
    Text {
        width: glass.width
        text: glyph.text; font: glyph.font; textFormat: Text.PlainText
        wrapMode: glyph.wrapMode; maximumLineCount: glyph.maximumLineCount; elide: glyph.elide
        color: glass.software ? "#e9f8ff" : "#65c7e4f8"
    }
    Rectangle {
        anchors.fill: parent
        visible: !glass.software
        gradient: Gradient {
            GradientStop { position: 0; color: "#f7ffffff" }
            GradientStop { position: 0.38; color: "#cce8fbff" }
            GradientStop { position: 0.52; color: "#287bc5ed" }
            GradientStop { position: 0.66; color: "#dfecfaff" }
            GradientStop { position: 1; color: "#6ca4c5ed" }
        }
        layer.enabled: !glass.software
        layer.effect: MultiEffect { maskEnabled: true; maskSource: glyph; autoPaddingEnabled: false }
    }
}
