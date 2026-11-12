import QtQuick
import Quickshell
import "file://@bundle@"

ShellRoot {
    FloatingWindow {
        implicitWidth: 688
        implicitHeight: 328
        MusicCard {
            id: card
            anchors.centerIn: parent
            width: 640
            height: 280
            player: mock
            lyricStatus: "synced"
            lyricLines: [{time: 0, text: "First test phrase"}, {time: 50, text: "Second test phrase"},
                {time: 100, text: "Current test phrase"}, {time: 150, text: "Next test phrase"},
                {time: 200, text: "Last test phrase"}]
        }
        QtObject {
            id: mock
            property bool isPlaying: false
            property bool positionSupported: true
            property bool lengthSupported: true
            property real length: 258
            property real position: 102
            property int uniqueId: 1
            property string trackTitle: "A title longer than the card can display without eliding"
            property string trackArtist: "Nocturne"
            property string trackArtUrl: ""
            property bool canControl: true
            property bool shuffleSupported: false
            property bool shuffle: false
            property bool canGoPrevious: true
            property bool canGoNext: true
            property bool canTogglePlaying: true
            property bool loopSupported: false
            property int loopState: 0
            property bool canSeek: true
            function previous() {}
            function next() {}
            function togglePlaying() { isPlaying = !isPlaying; }
        }
        Timer {
            interval: 100
            running: true
            onTriggered: {
                if (card.duration !== 258 || card.position !== 102)
                    throw new Error("MPRIS properties were not bound to the card");
                function find(item, name) {
                    if (item.objectName === name) return item;
                    for (const child of item.children) { const result = find(child, name); if (result) return result; }
                    return null;
                }
                const lyrics = find(card, "music-lyrics");
                if (!lyrics || lyrics.activeIndex !== 2) throw new Error("Current lyric did not follow position");
                mock.position = 151;
                if (lyrics.activeIndex !== 3) throw new Error("Forward seek did not update lyrics");
                mock.position = 5;
                if (lyrics.activeIndex !== 0) throw new Error("Backward seek did not update lyrics");
                card.player = null;
                Qt.callLater(function() {
                    if (card.duration !== 0 || card.position !== 0)
                        throw new Error("Player removal left stale state");
                    console.log("NOCTURNE_CARD_CHECK_PASSED");
                    Qt.quit();
                });
            }
        }
    }
}
