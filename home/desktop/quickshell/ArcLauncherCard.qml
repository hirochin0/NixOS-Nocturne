import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "BranchLogic.js" as BranchLogic

Item {
    id: root
    readonly property int pageSize: BranchLogic.capacity()
    readonly property real canvasWidth: pageApps.length > 10 ? 1140 : 790
    readonly property real canvasHeight: pageApps.length > 10 ? 650 : 590
    implicitWidth: surfaceOpen ? canvasWidth : 120
    implicitHeight: surfaceOpen ? canvasHeight : 120
    readonly property real originX: tile.x + tile.width / 2
    readonly property real originY: tile.y + tile.height / 2
    property var appEntries: DesktopEntries.applications.values
    readonly property real layoutScale: Math.min(1, (width - 40) / (canvasWidth - 40), (height - 40) / (canvasHeight - 40))
    property int nodeRevision: 0
    readonly property alias tileItem: tile
    readonly property alias pageControls: pagination
    function nodeAt(index) {
        const revision = nodeRevision;
        return index >= 0 ? appNodes.itemAt(index) : null;
    }
    property bool opened: false
    property bool surfaceOpen: false
    property int page: 0
    property var settings: ({})
    readonly property var apps: Array.isArray(settings.apps) ? settings.apps : []
    readonly property int pages: Math.max(1, Math.ceil(apps.length / pageSize))
    readonly property var pageApps: apps.slice(page * pageSize, page * pageSize + pageSize)
    property real bloom: opened ? 1 : 0
    Behavior on bloom { NumberAnimation { duration: 460; easing.type: Easing.OutCubic } }
    onOpenedChanged: {
        if (opened) { surfaceOpen = true; collapse.stop(); }
        else collapse.restart();
    }
    Timer { id: collapse; interval: 650; onTriggered: root.surfaceOpen = false }
    function apply(text) {
        try {
            const value = JSON.parse(text);
            if (!value || typeof value !== "object" || !Array.isArray(value.apps)
                || !value.apps.every(a => a && typeof a.desktopId === "string")) return;
            if (typeof value.image === "string" && value.image.startsWith("~/"))
                value.image = Quickshell.env("HOME") + value.image.slice(1);
            root.settings = value;
            root.page = 0;
        } catch (e) { console.warn("Launcher: invalid JSON; keeping previous settings", e); }
    }
    FileView {
        path: String(Qt.resolvedUrl("launcher-defaults.json")).replace("file://", "")
        onLoaded: { if (!Object.keys(root.settings).length) root.apply(text()); }
    }
    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/nocturne/launcher.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.apply(text())
    }
    function entry(app) {
        return root.appEntries.find(e => e.id === app.desktopId || e.id === app.desktopId + ".desktop");
    }
    function launch(app) {
        const desktop = entry(app);
        if (desktop) { desktop.execute(); root.opened = false; }
        else console.warn("Launcher: desktop entry not found:", app.desktopId);
    }
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.opened = false
        Canvas {
            id: links
            anchors.fill: parent
            opacity: root.bloom
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.clearRect(0, 0, width, height);
                ctx.lineCap = "round";
                for (let i = 0; i < appNodes.count; ++i) {
                    const node = appNodes.itemAt(i);
                    if (!node) continue;
                    const parent = node.parentNode;
                    const source = parent ? {x: parent.x + 31, y: parent.y + 31} : {x: root.originX, y: root.originY};
                    const sourceRadius = parent ? 35 : 55;
                    const next = { x: node.x + 31, y: node.y + 31, reveal: node.reveal };
                    const dx = next.x - source.x, dy = next.y - source.y;
                    const distance = Math.sqrt(dx * dx + dy * dy);
                    if (distance > sourceRadius + 37) {
                        const alpha = Math.min(1, Math.max(0, Math.min(next.reveal, parent ? parent.reveal : 1)));
                        ctx.beginPath();
                        const startX = source.x + dx / distance * sourceRadius;
                        const startY = source.y + dy / distance * sourceRadius;
                        const endX = next.x - dx / distance * 35;
                        const endY = next.y - dy / distance * 35;
                        ctx.moveTo(startX, startY);
                        ctx.lineTo(endX, endY);
                        ctx.strokeStyle = Qt.alpha(Theme.cyan, alpha * 0.12);
                        const branchWidth = Math.max(1, 2.3 - (node.depth - 1) * 0.5);
                        ctx.lineWidth = branchWidth + 2;
                        ctx.stroke();
                        ctx.strokeStyle = Qt.alpha(Theme.cyan, alpha * 0.7);
                        ctx.lineWidth = branchWidth;
                        ctx.stroke();
                    }
                }
            }
        }
        Repeater {
            id: appNodes
            onItemAdded: { root.nodeRevision++; links.requestPaint(); }
            onItemRemoved: { root.nodeRevision++; links.requestPaint(); }
            model: root.pageApps
            delegate: Item {
                id: satellite
                required property var modelData
                required property int index
                objectName: "branch-node-" + index
                property real reveal: 0
                onXChanged: links.requestPaint()
                onYChanged: links.requestPaint()
                onRevealChanged: links.requestPaint()
                readonly property int parentIndex: BranchLogic.parentIndex(root.pageApps, index)
                readonly property int depth: BranchLogic.depth(root.pageApps, index)
                readonly property var parentNode: root.nodeAt(parentIndex)
                readonly property real startX: parentNode ? parentNode.x + 31 : root.originX
                readonly property real startY: parentNode ? parentNode.y + 31 : root.originY
                readonly property real targetX: root.originX + (BranchLogic.position(index).x - 60) * root.layoutScale
                readonly property real targetY: root.originY + (BranchLogic.position(index).y - 60) * root.layoutScale
                x: startX + (targetX - startX) * reveal - 31
                y: startY + (targetY - startY) * reveal - 31
                width: 62; height: 86
                opacity: Math.max(0, Math.min(1, reveal))
                scale: Math.max(0.1, reveal) * (hover.containsMouse ? 1.1 : 1)
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Component.onCompleted: unfold.restart()
                Connections {
                    target: root
                    function onOpenedChanged() { unfold.restart(); }
                }
                SequentialAnimation {
                    id: unfold
                    PauseAnimation { duration: root.opened ? BranchLogic.openDelay(root.pageApps, satellite.index) : Math.max(0, 4 - satellite.depth) * 75 }
                    NumberAnimation {
                        target: satellite; property: "reveal"
                        to: root.opened ? 1 : 0
                        duration: root.opened ? 620 : 300
                        easing.type: root.opened ? Easing.OutBack : Easing.InCubic
                        easing.overshoot: 0.4
                    }
                }
                Rectangle {
                    width: 62; height: 62; radius: 20
                    color: hover.containsMouse ? Theme.elevated : Theme.surface
                    border.color: hover.containsMouse ? Theme.cyan : Qt.alpha(Theme.muted, 0.25)
                    Behavior on border.color { ColorAnimation { duration: 170 } }
                    AppIcon {
                        anchors.centerIn: parent
                        width: 32; height: 32
                        iconName: { const e = root.entry(satellite.modelData); return e ? e.icon : satellite.modelData.desktopId; }
                        smooth: true
                    }
                }
                Text {
                    y: 67; anchors.horizontalCenter: parent.horizontalCenter
                    width: 84; horizontalAlignment: Text.AlignHCenter
                    text: satellite.modelData.name || satellite.modelData.desktopId
                    elide: Text.ElideRight
                    color: hover.containsMouse ? Theme.text : Theme.muted
                    font { family: Theme.roundFont; pixelSize: 11; weight: Font.Bold }
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.opened && satellite.reveal > 0.85
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launch(satellite.modelData)
                }
                ToolTip.visible: hover.containsMouse && root.opened
                ToolTip.text: satellite.modelData.name || satellite.modelData.desktopId
            }
        }
        Row {
            id: pagination
            x: parent.width - 155; y: parent.height - 42; spacing: 12
            opacity: root.bloom
            visible: root.surfaceOpen && root.pages > 1
            ActionButton { text: "‹"; enabled: root.page > 0; onClicked: root.page-- }
            Text { text: (root.page + 1) + " / " + root.pages; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
            ActionButton { text: "›"; enabled: root.page + 1 < root.pages; onClicked: root.page++ }
        }
        Rectangle {
            id: tile
            x: 12; y: 12; width: 96; height: 96; radius: 22
            color: Theme.surface
            border.color: tileMouse.containsMouse || root.opened ? Theme.cyan : Qt.alpha(Theme.muted, 0.4)
            border.width: 2
            scale: tileMouse.pressed ? 0.92 : tileMouse.containsMouse ? 1.06 : 1
            rotation: root.opened ? -5 : 0
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
            Behavior on rotation { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }

            Image {
                id: artwork
                anchors.fill: parent; anchors.margins: 5
                source: root.settings.image || Qt.resolvedUrl("launcher.svg")
                fillMode: Image.PreserveAspectCrop
                layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
                layer.effect: MultiEffect { maskEnabled: true; maskSource: imageMask }
                smooth: true
                onStatusChanged: if (status === Image.Error) source = Qt.resolvedUrl("launcher.svg")
            }
            Rectangle {
                id: imageMask
                width: 86; height: 86; radius: 18
                visible: false; layer.enabled: true
            }
            MouseArea {
                id: tileMouse
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: root.opened = !root.opened
            }
        }
    }
}
