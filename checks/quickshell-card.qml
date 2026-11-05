import QtQuick
import Quickshell
import "file://@bundle@"

ShellRoot {
    FloatingWindow {
        implicitWidth: 528
        implicitHeight: 256
        MusicCard {
            id: card
            anchors.centerIn: parent
            width: 480
            height: 208
            player: mock
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
