import QtQuick

Item {
    id: glass
    property string text: ""
    property int maxLines: 5
    property real pixelSize: 15
    property real maxWidth: 560
    implicitWidth: Math.min(maxWidth, glyph.implicitWidth)
    implicitHeight: glyph.implicitHeight
    Text {
        x: 0; y: 0.6
        width: glass.width
        text: glyph.text; font: glyph.font; textFormat: Text.PlainText
        wrapMode: glyph.wrapMode; maximumLineCount: glyph.maximumLineCount; elide: glyph.elide
        color: "#24001338"
    }
    Text {
        id: glyph
        width: glass.width
        text: glass.text
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        maximumLineCount: glass.maxLines
        elide: Text.ElideRight
        font { family: Theme.roundFont; pixelSize: glass.pixelSize; weight: Font.Normal; variableAxes: ({"wght": 400}); kerning: true }
        color: "#fcfdff"
    }
}
