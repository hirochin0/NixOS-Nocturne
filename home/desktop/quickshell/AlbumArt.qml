import QtQuick

Image {
    property var player: null
    property real side: 38
    width: side
    height: side
    source: player ? player.trackArtUrl || "" : ""
    sourceSize: Qt.size(Math.ceil(side * 2), Math.ceil(side * 2))
    fillMode: Image.PreserveAspectCrop
    clip: true
    smooth: true
    asynchronous: true
    visible: status === Image.Ready
    Accessible.role: Accessible.Graphic
    Accessible.name: player ? "Album artwork: " + (player.trackTitle || "Spotify") : "Album artwork"
}
