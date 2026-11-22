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
        WindowPreview { id: pngPreview; x: 500; y: 100; width: 64; height: 64 }
        QtObject { id: missing; property string address: ""; property var lastIpcObject: ({size:[1920,1080]}) }
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
                if (hint.address !== "" || !hint.preview) throw new Error("Missing screenshot did not use fallback");
                if (hint.dimensions.width > 480 || hint.dimensions.height > 360) throw new Error("Preview exceeded bounds");
                water.appear(); input.wait(180);
                if (water.entrance <= 0) throw new Error("Droplet did not animate");
                input.wait(600);
                if (Math.abs(water.entrance - 1) > 0.001 || Math.abs(water.ripple) > 0.001) throw new Error("Droplet did not settle");
                const image = input.grabImage(water);
                if (image.red(200, 100) !== 69 || image.green(200, 100) !== 96 || image.blue(200, 100) !== 120)
                    throw new Error("Preview content was hidden or rendered black");
                pngPreview.active = true;
                pngPreview.acceptResult(JSON.stringify({ok:true,width:2,height:2,image:"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGP8z8DAwMDAxMDAwMDAAAANHQEDasKb6QAAAABJRU5ErkJggg=="}));
                input.wait(100);
                if (!pngPreview.ready) throw new Error("PNG did not load into Image");
                const pngImage = input.grabImage(pngPreview);
                if (pngImage.red(32, 32) !== 255 || pngImage.green(32, 32) !== 0 || pngImage.blue(32, 32) !== 0)
                    throw new Error("PNG pixels did not render");
                // Test the assembled hint: testing Image alone missed the
                // backdrop covering it after children were reparented.
                hint.active = false;
                hint.active = true;
                input.wait(450);
                const fullPreview = input.findChild(hint, "window-preview");
                const fullSurface = input.findChild(hint, "preview-surface");
                if (!fullPreview || !fullSurface) throw new Error("Full preview components missing");
                fullPreview.acceptResult(JSON.stringify({ok:true,width:1920,height:1080,image:pngPreview.imageData}));
                input.wait(150);
                if (!fullPreview.ready) throw new Error("Full hint image failed to load");
                const fullImage = input.grabImage(fullSurface);
                const cx = Math.floor(fullImage.width / 2), cy = Math.floor(fullImage.height / 2);
                if (fullImage.red(cx, cy) !== 255 || fullImage.green(cx, cy) !== 0 || fullImage.blue(cx, cy) !== 0)
                    throw new Error("Full hint backdrop covered the captured image");
                hint.dismiss();
                pngPreview.active = false;
                if (pngPreview.imageData.length) throw new Error("Preview retained image after closing");
                water.disappear();
                console.log("NOCTURNE_GLASS_PREVIEW_CHECK_PASSED");
                Qt.quit();
            }
        }
    }
}
