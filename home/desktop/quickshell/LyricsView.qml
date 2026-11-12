import QtQuick
import "LyricsLogic.js" as LyricsLogic

Item {
    id: lyrics
    property var lines: []
    property real position: 0
    property string status: "idle"
    readonly property int activeIndex: LyricsLogic.activeIndex(lines, position)
    readonly property real lineHeight: height / 5
    signal retryRequested()
    clip: true
    ListView {
        id: phrases
        objectName: "lyrics-phrases"
        anchors.fill: parent
        visible: lyrics.lines.length > 0
        model: lyrics.lines
        interactive: false
        currentIndex: Math.max(0, lyrics.activeIndex)
        preferredHighlightBegin: height / 2 - lyrics.lineHeight / 2
        preferredHighlightEnd: height / 2 + lyrics.lineHeight / 2
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 240
        highlight: Item {}
        header: Item { width: phrases.width; height: lyrics.lineHeight * 2 }
        footer: Item { width: phrases.width; height: lyrics.lineHeight * 2 }
        delegate: Item {
            id: phrase
            objectName: "lyric-line-" + index
            required property var modelData
            required property int index
            width: phrases.width
            height: lyrics.lineHeight
            readonly property bool focusedLine: index === lyrics.activeIndex
            opacity: focusedLine ? 1 : Math.abs(index - Math.max(0, lyrics.activeIndex)) === 1 ? 0.5 : 0.25
            scale: focusedLine ? 1 : 0.97
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Text {
                anchors.fill: parent
                text: phrase.modelData.text || "···"
                textFormat: Text.PlainText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: phrase.focusedLine ? Theme.text : Theme.muted
                font { family: Theme.roundFont; pixelSize: phrase.focusedLine ? 18 : 14; bold: phrase.focusedLine }
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 10
                elide: Text.ElideRight
                style: Text.Outline
                styleColor: "#6020293c"
            }
        }
    }
    Text {
        anchors.centerIn: parent
        visible: lyrics.lines.length === 0
        text: lyrics.status === "loading" ? "Loading lyrics…"
            : lyrics.status === "instrumental" ? "Instrumental"
            : lyrics.status === "offline" ? "Lyrics unavailable · Click to retry"
            : "Synced lyrics unavailable"
        color: Theme.muted
        font { family: Theme.roundFont; pixelSize: 12 }
        textFormat: Text.PlainText
        MouseArea {
            anchors.fill: parent
            enabled: lyrics.status === "offline"
            cursorShape: Qt.PointingHandCursor
            onClicked: lyrics.retryRequested()
        }
    }
}
