import QtQuick
import QtQuick.Effects

Item {
    id: board
    property real cornerRadius: 18
    property real lightX: width * 0.7
    readonly property bool software: GraphicsInfo.api === GraphicsInfo.Software
    Rectangle { anchors.fill: parent; radius: board.cornerRadius; color: "#ad121b2a" }
    Image {
        id: backdrop
        source: Theme.wallpaperPath
        sourceSize: Qt.size(640, 400)
        width: board.width; height: board.height
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
        layer.enabled: !board.software
    }
    Rectangle { id: mask; anchors.fill: parent; radius: board.cornerRadius; color: "white"; visible: false; layer.enabled: !board.software }
    MultiEffect {
        anchors.fill: parent
        visible: !board.software && backdrop.status === Image.Ready
        source: backdrop
        blurEnabled: true; blurMax: 32; blur: 0.7
        saturation: -0.25
        opacity: 0.26
        maskEnabled: true; maskSource: mask
        autoPaddingEnabled: false
    }
    Rectangle {
        anchors.fill: parent
        radius: board.cornerRadius
        gradient: Gradient {
            GradientStop { position: 0; color: "#42f1fbff" }
            GradientStop { position: 0.16; color: "#0ff5fbff" }
            GradientStop { position: 0.6; color: "#061d3358" }
            GradientStop { position: 1; color: "#245784a5" }
        }
        border.width: 1
        border.color: "#80d9f4ff"
    }
    Rectangle {
        x: 8; y: 1
        width: Math.max(0, board.width - 16); height: 1
        radius: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: Math.max(0.1, Math.min(0.9, board.lightX / Math.max(1, board.width))); color: "#d0ffffff" }
            GradientStop { position: 1; color: "transparent" }
        }
    }
    Rectangle { x: 2; y: 10; width: 1; height: Math.max(0, board.height - 20); color: "#2ae1f6ff"; radius: 1 }
    Rectangle { x: board.width - 3; y: 10; width: 1; height: Math.max(0, board.height - 20); color: "#3ba0c6ed"; radius: 1 }
}
