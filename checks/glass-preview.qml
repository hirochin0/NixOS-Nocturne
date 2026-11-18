import QtQuick
import QtTest
import Quickshell
import "file://@bundle@"
ShellRoot {
    FloatingWindow {
        implicitWidth: 1000; implicitHeight: 800
        Rectangle { id: anchorButton; width: 40; height: 40; color: "#243044" }
        GlassHint { id: hint; owner: anchorButton; text: "Network · Connected" }
        LiquidGlassText { id: label; x: 20; y: 100; width: implicitWidth; height: implicitHeight; text: "Literal <b>title</b> · Workspace 3" }
        LiquidPreviewSurface {
            id: water; x: 20; y: 180; width: 420; height: 260
            Rectangle { parent: water.contentItem; anchors.fill: parent; color: "#456078" }
        }
        QtObject { id: missing; property var wayland: null; property var lastIpcObject: ({size:[1920,1080]}) }
        TestCase { id: input; name: "GlassPreview"; when: false }
        Timer {
            interval: 300; running: true
            onTriggered: {
                if (label.implicitWidth <= 0 || label.implicitHeight <= 0) throw new Error("Glass text has no layout");
                hint.active = true;
                input.wait(180);
                if (hint.displayed) throw new Error("Hover delay not respected");
                input.wait(250);
                if (!hint.displayed) throw new Error("Hover did not display hint");
                hint.dismiss();
                if (hint.displayed) throw new Error("Interaction did not dismiss hint");
                hint.previewTarget = missing;
                if (hint.source !== null || !hint.preview) throw new Error("Missing screenshot did not use fallback");
                if (hint.dimensions.width > 480 || hint.dimensions.height > 360) throw new Error("Preview exceeded bounds");
                water.appear(); input.wait(180);
                if (water.entrance <= 0) throw new Error("Droplet did not animate");
                input.wait(600);
                if (Math.abs(water.entrance - 1) > 0.001 || Math.abs(water.ripple) > 0.001) throw new Error("Droplet did not settle");
                water.disappear();
                console.log("NOCTURNE_GLASS_PREVIEW_CHECK_PASSED");
                Qt.quit();
            }
        }
    }
}
