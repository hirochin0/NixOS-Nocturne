import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: surfaceOpen ? 400 : 88
    implicitHeight: surfaceOpen ? 400 : 88
    property bool opened: false
    property bool surfaceOpen: false
    property int page: 0
    property var settings: ({})
    readonly property var apps: Array.isArray(settings.apps) ? settings.apps : []
    readonly property int pages: Math.max(1, Math.ceil(apps.length / 6))
    readonly property var pageApps: apps.slice(page * 6, page * 6 + 6)
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
        return DesktopEntries.applications.values.find(e => e.id === app.desktopId || e.id === app.desktopId + ".desktop");
    }
    function launch(app) {
        const desktop = entry(app);
        if (desktop) { desktop.execute(); root.opened = false; }
        else console.warn("Launcher: desktop entry not found:", app.desktopId);
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 28
        opacity: root.bloom * 0.96
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.elevated }
            GradientStop { position: 1; color: Theme.bg }
        }
        border.color: Qt.alpha(Theme.cyan, 0.22)
        border.width: 1
    }
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.opened = false
        Text {
            x: 108; y: 26
            text: "ORBIT"
            font { family: Theme.font; pixelSize: 13; letterSpacing: 4 }
            color: Theme.cyan
            opacity: root.bloom
        }
        Text {
            x: 108; y: 48
            text: root.apps.length + " applications"
            font { family: Theme.font; pixelSize: 10 }
            color: Theme.muted
            opacity: root.bloom
        }
        Canvas {
            anchors.fill: parent
            opacity: root.bloom * 0.22
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = Theme.cyan;
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.arc(44, 44, 270, 0, Math.PI / 2);
                ctx.stroke();
            }
        }
        Repeater {
            model: root.pageApps
            delegate: Item {
                id: satellite
                required property var modelData
                required property int index
                property real reveal: 0
                readonly property real angle: (index * 18) * Math.PI / 180 + (1 - reveal) * 0.32
                x: 44 + Math.cos(angle) * 270 * reveal - 31
                y: 44 + Math.sin(angle) * 270 * reveal - 31
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
                    PauseAnimation { duration: root.opened ? satellite.index * 45 : (5 - satellite.index) * 25 }
                    NumberAnimation {
                        target: satellite; property: "reveal"
                        to: root.opened ? 1 : 0
                        duration: root.opened ? 470 : 240
                        easing.type: root.opened ? Easing.OutBack : Easing.InCubic
                        easing.overshoot: 1.1
                    }
                }
                Rectangle {
                    width: 62; height: 62; radius: 20
                    color: hover.containsMouse ? Theme.elevated : Theme.surface
                    border.color: hover.containsMouse ? Theme.cyan : Qt.alpha(Theme.muted, 0.25)
                    Behavior on border.color { ColorAnimation { duration: 170 } }
                    Text {
                        anchors.centerIn: parent
                        visible: !root.entry(satellite.modelData)
                        text: (satellite.modelData.name || satellite.modelData.desktopId).slice(0, 1).toUpperCase()
                        color: Theme.cyan
                        font { family: Theme.font; pixelSize: 24 }
                    }
                    Image {
                        anchors.centerIn: parent
                        width: 32; height: 32
                        source: { const e = root.entry(satellite.modelData); return e ? Quickshell.iconPath(e.icon) : ""; }
                        smooth: true
                    }
                }
                Text {
                    y: 67; anchors.horizontalCenter: parent.horizontalCenter
                    width: 84; horizontalAlignment: Text.AlignHCenter
                    text: satellite.modelData.name || satellite.modelData.desktopId
                    elide: Text.ElideRight
                    color: hover.containsMouse ? Theme.text : Theme.muted
                    font { family: Theme.font; pixelSize: 10 }
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.opened
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launch(satellite.modelData)
                }
                ToolTip.visible: hover.containsMouse && root.opened
                ToolTip.text: satellite.modelData.name || satellite.modelData.desktopId
            }
        }
        Row {
            x: 164; y: 354; spacing: 12
            opacity: root.bloom
            visible: root.surfaceOpen
            ActionButton { text: "‹"; enabled: root.page > 0; onClicked: root.page-- }
            Text { text: (root.page + 1) + " / " + root.pages; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
            ActionButton { text: "›"; enabled: root.page + 1 < root.pages; onClicked: root.page++ }
        }
        Rectangle {
            id: tile
            x: 12; y: 12; width: 64; height: 64; radius: 16
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
                width: 54; height: 54; radius: 12
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
