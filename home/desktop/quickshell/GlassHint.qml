import QtQuick
import Quickshell
import Quickshell.Wayland
import "PreviewLogic.js" as PreviewLogic

Scope {
    id: hint
    required property Item owner
    property string text: ""
    property var previewTarget: null
    property bool active: false
    property bool displayed: false
    property bool captureFailed: false
    readonly property bool preview: !!previewTarget
    readonly property var source: previewTarget && previewTarget.wayland ? previewTarget.wayland : null
    readonly property bool captureReady: !!captureLoader.item && captureLoader.item.hasContent
    readonly property var sourceSize: PreviewLogic.windowSize(previewTarget)
    readonly property var dimensions: PreviewLogic.dimensions(
        captureReady ? captureLoader.item.sourceSize.width : sourceSize.width,
        captureReady ? captureLoader.item.sourceSize.height : sourceSize.height,
        popup.screen ? popup.screen.width : 1280, popup.screen ? popup.screen.height : 800)
    function report(status) {
        console.log("NOCTURNE_PREVIEW", status, "address=" + (previewTarget ? previewTarget.address : "none"),
            "source=" + !!source, "ready=" + captureReady,
            "view=" + (captureLoader.item ? captureLoader.item.width + "x" + captureLoader.item.height : "none"));
    }
    function dismiss() { delay.stop(); leave.stop(); displayed = false; }
    onActiveChanged: {
        if (active && text.length) {
            leave.stop();
            if (!displayed) delay.restart();
        } else { delay.stop(); leave.restart(); }
    }
    onTextChanged: { if (!text.length) dismiss(); else if (active && !displayed) delay.restart(); }
    onSourceChanged: {
        captureDelay.stop(); captureTimeout.stop();
        if (displayed && source) { captureFailed = false; captureDelay.restart(); }
    }
    onPreviewTargetChanged: {
        captureFailed = false;
        if (displayed) captureDelay.restart();
    }
    Timer { id: delay; interval: 350; onTriggered: if (hint.active && hint.text.length) hint.displayed = true }
    Timer { id: leave; interval: 120; onTriggered: hint.displayed = false }
    Timer { id: captureTimeout; interval: 2000; onTriggered: if (popup.visible && hint.preview && !hint.captureReady) {
        hint.report(hint.source ? "capture-timeout" : "missing-wayland-handle");
        hint.captureFailed = true;
    } }
    Timer {
        id: captureDelay
        interval: 60
        onTriggered: if (popup.visible && captureLoader.item && captureLoader.item.captureSource && !hint.captureReady) { captureLoader.item.captureFrame(); captureTimeout.restart(); }
    }
    PopupWindow {
        id: popup
        anchor.item: hint.owner
        anchor.rect.x: hint.owner.width / 2 - width / 2
        anchor.rect.y: hint.owner.height + 10
        anchor.rect.width: 1; anchor.rect.height: 1
        anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.SlideY
        grabFocus: false
        color: "transparent"
        visible: hint.displayed && hint.owner.visible && hint.owner.enabled
        implicitWidth: hint.preview ? hint.dimensions.width : Math.min(600, label.implicitWidth + 32)
        implicitHeight: hint.preview ? hint.dimensions.height : label.implicitHeight + 28
        onWidthChanged: if (visible) anchor.updateAnchor()
        onHeightChanged: if (visible) anchor.updateAnchor()
        onVisibleChanged: {
            if (visible) { hint.captureFailed = false; if (hint.preview) { water.appear(); captureTimeout.restart(); hint.report("opened"); } if (hint.source) captureDelay.restart(); }
            else { captureDelay.stop(); captureTimeout.stop(); water.disappear(); }
        }
        GlassBoard { id: board; anchors.fill: parent }
        LiquidGlassText {
            id: label
            x: 16; y: 12
            width: Math.min(implicitWidth, popup.width - 32)
            height: implicitHeight
            maxWidth: Math.max(1, Math.min(560, hint.preview ? popup.width - 32 : (popup.screen ? popup.screen.width - 64 : 560)))
            text: hint.text
            pixelSize: hint.preview ? 14 : 13
            maxLines: hint.preview ? 2 : 5
        }
        LiquidPreviewSurface {
            id: water
            visible: hint.preview
            x: hint.dimensions.padding
            y: hint.dimensions.padding + hint.dimensions.heading
            width: hint.dimensions.imageWidth
            height: hint.dimensions.imageHeight
            Rectangle { parent: water.contentItem; anchors.fill: parent; color: "#171f30" }
            Loader {
                id: captureLoader
                parent: water.contentItem
                anchors.fill: parent
                // The popup and its render window must exist before initializing
                // Quickshell's screencopy context and buffer manager.
                active: popup.visible && hint.preview && !!hint.source && !hint.captureFailed
                onLoaded: captureDelay.restart()
                sourceComponent: Component {
                    ScreencopyView {
                        id: copy
                        anchors.fill: parent
                        captureSource: popup.visible && !hint.captureFailed ? hint.source : null
                        live: false
                        paintCursor: false
                        onHasContentChanged: if (hasContent) {
                            captureTimeout.stop();
                            console.log("NOCTURNE_PREVIEW frame-received", "size=" + sourceSize.width + "x" + sourceSize.height,
                                "view=" + width + "x" + height);
                        }
                        onStopped: { hint.report("capture-stopped"); hint.captureFailed = true; }
                    }
                }
            }
            LiquidGlassText {
                parent: water.contentItem
                anchors.centerIn: parent
                width: Math.min(implicitWidth, parent.width - 32)
                height: implicitHeight
                maxWidth: Math.max(1, parent.width - 32)
                text: hint.captureFailed || !hint.source ? "Preview unavailable" : "Loading preview…"
                visible: !hint.captureReady
                pixelSize: 14
            }
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
            onEntered: leave.stop()
            onExited: if (!hint.active) leave.restart()
            onPositionChanged: mouse => {
                board.lightX = mouse.x;
                water.cursorX = mouse.x - water.x;
                water.cursorY = mouse.y - water.y;
                water.tension = 0.16;
            }
            onContainsMouseChanged: if (!containsMouse) water.tension = 0
        }
    }
}
