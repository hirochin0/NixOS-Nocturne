import QtQuick
import Quickshell
import Quickshell.Wayland
import "DesktopLogic.js" as DesktopLogic

PanelWindow {
    id: window
    property var snapshots: []
    property var plan: null
    property string phase: "idle"
    property real progress: 0
    property bool frozenBackground: false
    signal captured()
    signal captureFailed()
    signal retreated()
    signal returned()
    signal restoreRequested()
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nocturne-desktop-reveal"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    visible: phase !== "idle"
    color: "transparent"
    // Only edge strips take clicks; the desktop and its widgets remain interactive.
    mask: Region {
        Region { x: 0; y: 0; width: window.phase === "desktop" ? 30 : 0; height: window.height }
        Region { x: window.width - 30; y: 0; width: window.phase === "desktop" ? 30 : 0; height: window.height }
        Region { x: 0; y: 0; width: window.width; height: window.phase === "desktop" ? 30 : 0 }
        Region { x: 0; y: window.height - 30; width: window.width; height: window.phase === "desktop" ? 30 : 0 }
    }
    function capture() {
        progress = 0;
        frozenBackground = false;
        phase = "capture";
        captureTimeout.restart();
        Qt.callLater(function() {
            background.captureFrame();
            for (let i = 0; i < copies.count; i++) copies.itemAt(i).captureFrame();
            checkReady();
        });
    }
    function checkReady() {
        if (phase !== "capture" || !background.hasContent) return;
        for (let i = 0; i < copies.count; i++) if (!copies.itemAt(i).hasContent) return;
        captureTimeout.stop();
        phase = "switching";
        frozenBackground = true;
        // Let the frozen frame reach the display before switching the real workspace.
        freezeDelay.restart();
    }
    function retreat() {
        frozenBackground = false;
        phase = "retreat";
        motion.to = 1;
        motion.restart();
    }
    function returnWindows() {
        phase = "return";
        motion.to = 0;
        motion.restart();
    }
    function reset() {
        captureTimeout.stop(); freezeDelay.stop(); motion.stop();
        frozenBackground = false; phase = "idle"; snapshots = []; plan = null;
    }
    Timer { id: captureTimeout; interval: 1800; onTriggered: window.captureFailed() }
    Timer { id: freezeDelay; interval: 40; onTriggered: window.captured() }
    NumberAnimation {
        id: motion
        target: window; property: "progress"
        duration: 540; easing.type: Easing.InOutCubic
        onFinished: {
            if (window.phase === "retreat") { window.phase = "desktop"; window.retreated(); }
            else if (window.phase === "return") { window.frozenBackground = true; window.returned(); }
        }
    }
    ScreencopyView {
        id: background
        anchors.fill: parent
        captureSource: window.visible ? window.screen : null
        live: false; paintCursor: false
        opacity: window.frozenBackground ? 1 : 0
        onHasContentChanged: window.checkReady()
    }
    Item {
        anchors.fill: parent
        clip: true
        visible: !window.frozenBackground
        Repeater {
            id: copies
            model: window.snapshots
            ScreencopyView {
                id: copy
                objectName: "retreat-" + modelData.address
                required property var modelData
                readonly property var destination: DesktopLogic.target(modelData, window.width, window.height)
                x: modelData.x + (destination.x - modelData.x) * window.progress
                y: modelData.y + (destination.y - modelData.y) * window.progress
                width: modelData.width; height: modelData.height
                captureSource: modelData.source
                live: false; paintCursor: false
                opacity: window.phase === "capture" || window.phase === "desktop" ? 0 : 1
                onHasContentChanged: window.checkReady()
            }
        }
    }
    DesktopCurtain {
        anchors.fill: parent
        opacity: window.phase === "desktop" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
        onRestoreRequested: window.restoreRequested()
    }
}
