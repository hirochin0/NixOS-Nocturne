import QtQuick

Item {
    id: glass
    property string text: ""
    property int maxLines: 5
    property real pixelSize: 15
    property real maxWidth: 560
    property string fontFamily: Theme.roundFont
    property int wrapMode: Text.Wrap
    // Measure before wrapping. Measuring the width-constrained glyph can
    // shrink a popup to its longest word and cause an unwanted extra line.
    implicitWidth: Math.min(maxWidth, Math.ceil(measure.implicitWidth))
    implicitHeight: glyph.implicitHeight
    Text {
        id: measure
        text: glass.text
        textFormat: Text.PlainText
        font: glyph.font
        wrapMode: Text.NoWrap
        visible: false
    }
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
        wrapMode: glass.wrapMode
        maximumLineCount: glass.maxLines
        elide: Text.ElideRight
        font { family: glass.fontFamily; pixelSize: glass.pixelSize; weight: Font.Normal; variableAxes: ({"wght": 400}); kerning: true }
        color: "#fcfdff"
    }
}
