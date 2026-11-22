import QtQuick
import Quickshell.Io

Item {
    id: preview
    property string address: ""
    property bool active: false
    property string imageData: ""
    property string error: ""
    property size originalSize: Qt.size(0, 0)
    property bool requestEnabled: false
    readonly property bool ready: image.status === Image.Ready
    function acceptResult(text) {
        try {
            const result = JSON.parse(text);
            if (!result.ok || !result.image || !result.image.startsWith("data:image/png;base64,")) {
                imageData = "";
                error = result.error || "invalid-capture-result";
                console.warn("NOCTURNE_PREVIEW", error);
                return;
            }
            originalSize = Qt.size(result.width, result.height);
            imageData = result.image;
        } catch (_) {
            imageData = "";
            error = "invalid-capture-result";
            console.warn("NOCTURNE_PREVIEW", error);
        }
    }
    function reset() { imageData = ""; error = ""; originalSize = Qt.size(0, 0); }
    function refresh() {
        reset();
        requestEnabled = false;
        restart.stop();
        if (active && address.length) restart.start();
    }
    onActiveChanged: refresh()
    onAddressChanged: refresh()
    Timer {
        id: restart
        interval: 0
        onTriggered: preview.requestEnabled = preview.active && preview.address.length > 0
    }
    Image {
        id: image
        anchors.fill: parent
        source: preview.active ? preview.imageData : ""
        fillMode: Image.PreserveAspectFit
        cache: false
        onStatusChanged: {
            if (status === Image.Ready)
                console.log("NOCTURNE_PREVIEW image-loaded", "size=" + preview.originalSize.width + "x" + preview.originalSize.height);
            else if (status === Image.Error) preview.error = "image-decode-failed";
        }
    }
    Loader {
        // Destroying the loader stops the helper when the hover ends. The PNG
        // travels through stdout and is never saved to a user's disk.
        active: preview.requestEnabled
        sourceComponent: Item {
            Process {
                command: [Theme.previewCommand, preview.address]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: if (preview.active) preview.acceptResult(text)
                }
                onExited: (exitCode, exitStatus) => {
                    if (preview.active && exitCode !== 0 && !preview.error.length) {
                        preview.error = "capture-helper-exit-" + exitCode;
                        console.warn("NOCTURNE_PREVIEW", preview.error);
                    }
                }
            }
        }
    }
}
