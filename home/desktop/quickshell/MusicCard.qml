import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "Logic.js" as Logic

Item {
    id: card
    required property var player
    property bool updating: true
    property var lyricLines: []
    property string lyricStatus: "idle"
    signal lyricsRetryRequested()
    implicitWidth: 640
    implicitHeight: 280
    readonly property real duration: player && player.lengthSupported ? player.length : 0
    readonly property real position: player && player.positionSupported ? player.position : 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 4
        Text {
            Layout.fillWidth: true
            text: card.player ? (card.player.trackTitle || "Spotify") : "Spotify"
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: Theme.text
            font { family: Theme.roundFont; pixelSize: 17; bold: true }
        }
        Text {
            Layout.fillWidth: true
            text: card.player ? (card.player.trackArtist || "") : ""
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: Theme.muted
            font { family: Theme.roundFont; pixelSize: 11 }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            ActionButton {
                frameless: true
                text: "󰒟"; hint: "Shuffle"
                enabled: !!card.player && card.player.canControl && card.player.shuffleSupported
                active: !!card.player && card.player.shuffle
                onClicked: card.player.shuffle = !card.player.shuffle
            }
            ActionButton {
                frameless: true
                text: "󰒮"; hint: "Previous"
                enabled: !!card.player && card.player.canGoPrevious
                onClicked: card.player.previous()
            }
            ActionButton {
                frameless: true
                accent: true
                text: card.player && card.player.isPlaying ? "󰏤" : "󰐊"
                hint: card.player && card.player.isPlaying ? "Pause" : "Play"
                enabled: !!card.player && card.player.canTogglePlaying
                onClicked: card.player.togglePlaying()
            }
            ActionButton {
                frameless: true
                text: "󰒭"; hint: "Next"
                enabled: !!card.player && card.player.canGoNext
                onClicked: card.player.next()
            }
            ActionButton {
                frameless: true
                text: card.player && card.player.loopState === MprisLoopState.Track ? "󰑘" : "󰑖"
                hint: "Repeat: off / playlist / track"
                enabled: !!card.player && card.player.canControl && card.player.loopSupported
                active: !!card.player && card.player.loopState !== MprisLoopState.None
                onClicked: {
                    var current = card.player.loopState;
                    card.player.loopState = current === MprisLoopState.None ? MprisLoopState.Playlist
                        : current === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                text: card.player && card.player.positionSupported ? Logic.timeText(card.position) : "--:--"
                color: Theme.muted; font.family: Theme.font; font.pixelSize: 11
            }
            Slider {
                id: seek
                property real pendingFraction: 0
                property var seekPlayer: null
                property int seekTrack: -1
                Layout.fillWidth: true
                from: 0
                to: Math.max(1, card.duration)
                enabled: !!card.player && card.player.canSeek && card.player.positionSupported && card.duration > 0
                // Do not write to MPRIS while dragging: commit a seek on release.
                Binding {
                    target: seek; property: "value"
                    value: Math.min(card.position, seek.to)
                    when: !seek.pressed
                    restoreMode: Binding.RestoreNone
                }
                onPressedChanged: {
                    if (pressed) {
                        seekPlayer = card.player;
                        seekTrack = card.player ? card.player.uniqueId : -1;
                        pendingFraction = position;
                    } else if (enabled && card.player === seekPlayer && card.player.uniqueId === seekTrack) {
                        card.player.position = Logic.seekPosition(pendingFraction, card.duration);
                    }
                }
                onMoved: pendingFraction = position
                background: Rectangle {
                    x: seek.leftPadding
                    y: seek.topPadding + seek.availableHeight / 2 - height / 2
                    implicitHeight: 4
                    width: seek.availableWidth
                    height: implicitHeight
                    radius: 2
                    color: Theme.elevated
                    Rectangle { width: seek.visualPosition * parent.width; height: parent.height; radius: 2; color: Theme.cyan }
                }
                handle: Rectangle {
                    x: seek.leftPadding + seek.visualPosition * (seek.availableWidth - width)
                    y: seek.topPadding + seek.availableHeight / 2 - height / 2
                    implicitWidth: 10; implicitHeight: 10; radius: 5
                    color: Theme.cyan
                    visible: seek.enabled
                }
            }
            Text {
                text: card.duration > 0 ? Logic.timeText(card.duration) : "--:--"
                color: Theme.muted; font.family: Theme.font; font.pixelSize: 11
            }
        }
        LyricsView {
            id: lyricView
            objectName: "music-lyrics"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 60
            lines: card.player && card.player.positionSupported ? card.lyricLines : []
            status: card.player && card.player.positionSupported ? card.lyricStatus : "unsynced"
            position: card.position
            onRetryRequested: card.lyricsRetryRequested()
        }
    }
}
