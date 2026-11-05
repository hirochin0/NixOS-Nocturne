import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "Logic.js" as Logic

Rectangle {
    id: card
    required property var player
    property bool updating: true
    implicitWidth: 480
    implicitHeight: 208
    radius: 20
    color: Qt.alpha(Theme.bg, 0.94)
    border.width: 1
    border.color: Qt.alpha(Theme.cyan, 0.55)
    readonly property real duration: player && player.lengthSupported ? player.length : 0
    readonly property real position: player && player.positionSupported ? player.position : 0

    // Native D-Bus events handle metadata. Only the visible, playing clock ticks.
    Timer {
        interval: 1000
        repeat: true
        running: card.updating && !!card.player && card.player.isPlaying && card.player.positionSupported
        onTriggered: card.player.positionChanged()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12
        RowLayout {
            spacing: 18
            Rectangle {
                Layout.preferredWidth: 132
                Layout.preferredHeight: 132
                radius: 12
                color: Theme.elevated
                clip: true
                Text {
                    anchors.centerIn: parent
                    text: "󰝚"
                    font.family: Theme.font
                    font.pixelSize: 46
                    color: Theme.muted
                }
                Image {
                    anchors.fill: parent
                    anchors.margins: 3
                    source: card.player ? card.player.trackArtUrl : ""
                    sourceSize.width: 264
                    sourceSize.height: 264
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 5
                Text {
                    text: "󰓇  SPOTIFY"
                    color: Theme.green
                    font.family: Theme.font
                    font.pixelSize: 11
                }
                Text {
                    Layout.fillWidth: true
                    text: card.player ? (card.player.trackTitle || "Spotify") : "Spotify"
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 18
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: card.player ? (card.player.trackArtist || "Unknown artist") : ""
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: 12
                }
                Item { Layout.fillHeight: true }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    ActionButton {
                        text: "󰒟"; hint: "Shuffle"
                        enabled: !!card.player && card.player.canControl && card.player.shuffleSupported
                        active: !!card.player && card.player.shuffle
                        onClicked: card.player.shuffle = !card.player.shuffle
                    }
                    ActionButton {
                        text: "󰒮"; hint: "Previous"
                        enabled: !!card.player && card.player.canGoPrevious
                        onClicked: card.player.previous()
                    }
                    ActionButton {
                        accent: true
                        text: card.player && card.player.isPlaying ? "󰏤" : "󰐊"
                        hint: card.player && card.player.isPlaying ? "Pause" : "Play"
                        enabled: !!card.player && card.player.canTogglePlaying
                        onClicked: card.player.togglePlaying()
                    }
                    ActionButton {
                        text: "󰒭"; hint: "Next"
                        enabled: !!card.player && card.player.canGoNext
                        onClicked: card.player.next()
                    }
                    ActionButton {
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
    }
}
