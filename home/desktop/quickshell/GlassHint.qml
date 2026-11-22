import QtQuick
import Quickshell
import "PreviewLogic.js" as PreviewLogic

Scope {
    id: hint
    required property Item owner
    property string text: ""
    property var previewTarget: null
    property bool active: false
    property bool displayed: false
    readonly property bool preview: !!previewTarget
    readonly property string address: previewTarget && previewTarget.address ? previewTarget.address : ""
    readonly property bool captureReady: windowPreview.ready
    readonly property var sourceSize: PreviewLogic.windowSize(previewTarget)
    readonly property var dimensions: PreviewLogic.dimensions(
        captureReady ? windowPreview.originalSize.width : sourceSize.width,
        captureReady ? windowPreview.originalSize.height : sourceSize.height,
        popup.screen ? popup.screen.width : 1280, popup.screen ? popup.screen.height : 800)
    function dismiss() { delay.stop(); leave.stop(); displayed = false; }
    onActiveChanged: {
        if (active && text.length) {
            leave.stop();
            if (!displayed) delay.restart();
        } else { delay.stop(); leave.restart(); }
    }
    onTextChanged: { if (!text.length) dismiss(); else if (active && !displayed) delay.restart(); }
    Timer { id: delay; interval: 350; onTriggered: if (hint.active && hint.text.length) hint.displayed = true }
    Timer { id: leave; interval: 120; onTriggered: hint.displayed = false }
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
            if (visible && hint.preview) water.appear();
            else water.disappear();
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
            objectName: "preview-surface"
            visible: hint.preview
            x: hint.dimensions.padding
            y: hint.dimensions.padding + hint.dimensions.heading
            width: hint.dimensions.imageWidth
            height: hint.dimensions.imageHeight
            // Reparented components do not necessarily retain declaration
            // order. Keep the backdrop behind the image and loading text.
            Rectangle { parent: water.contentItem; anchors.fill: parent; z: 0; color: "#171f30" }
            WindowPreview {
                id: windowPreview
                objectName: "window-preview"
                parent: water.contentItem
                anchors.fill: parent
                z: 1
                address: hint.address
                active: popup.visible && hint.preview
            }
            LiquidGlassText {
                parent: water.contentItem
                z: 2
                anchors.centerIn: parent
                width: Math.min(implicitWidth, parent.width - 32)
                height: implicitHeight
                maxWidth: Math.max(1, parent.width - 32)
                text: windowPreview.error.length || !hint.address.length ? "Preview unavailable" : "Loading preview…"
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
