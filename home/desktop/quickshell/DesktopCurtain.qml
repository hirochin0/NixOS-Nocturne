import QtQuick

Item {
    id: curtain
    signal restoreRequested()
    property real edgeSize: 30
    Repeater {
        model: 4
        Rectangle {
            id: edge
            required property int index
            readonly property bool verticalEdge: index < 2
            x: index === 1 ? curtain.width - width : 0
            y: index === 3 ? curtain.height - height : 0
            width: verticalEdge ? curtain.edgeSize : curtain.width
            height: verticalEdge ? curtain.height : curtain.edgeSize
            gradient: Gradient {
                orientation: edge.verticalEdge ? Gradient.Horizontal : Gradient.Vertical
                GradientStop { position: 0; color: edge.index === 0 || edge.index === 2 ? "#68878a90" : "transparent" }
                GradientStop { position: 1; color: edge.index === 0 || edge.index === 2 ? "transparent" : "#68878a90" }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: curtain.restoreRequested() }
        }
    }
}
