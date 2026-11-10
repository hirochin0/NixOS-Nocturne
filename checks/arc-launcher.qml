import QtQuick
import Quickshell
import "file://@bundle@"
ShellRoot {
    FloatingWindow {
        implicitWidth: 1140; implicitHeight: 650
        ArcLauncherCard { id: card; anchors.fill: parent }
        Timer {
            interval: 850; running: true
            onTriggered: {
                if (card.apps.length !== 10) throw new Error("Default app list not loaded");
                card.opened = true;
                verifyOpen.start();
            }
        }
        Timer {
            id: verifyOpen; interval: 1400
            onTriggered: {
                if (!card.surfaceOpen || card.bloom < 0.99) throw new Error("Open animation failed");
                const rootNode = card.nodeAt(0), child = card.nodeAt(3), grandchild = card.nodeAt(9);
                if (child.parentNode !== rootNode || card.nodeAt(1).parentNode || card.nodeAt(2).parentNode || grandchild.depth !== 3)
                    throw new Error("Application branches are not connected to parent nodes");
                for (let i = 0; i < 10; i++) if (card.nodeAt(i).reveal < 0.99) throw new Error("Branch did not unfold");
                const extra = Array.from({length: 11}, () => ({desktopId: "kitty"}));
                card.apply(JSON.stringify({image: "", apps: card.apps.concat(extra)}));
                verifyCapacity.start();
            }
        }
        Timer {
            id: verifyCapacity; interval: 2100
            onTriggered: {
                if (card.pages !== 1 || card.pageApps.length !== 21 || !card.nodeAt(20))
                    throw new Error("21 application capacity failed");
                for (let i = 0; i < 21; i++) if (card.nodeAt(i).reveal < 0.99) throw new Error("21 nodes did not unfold");
                card.apply('{"image":"","apps":[{"desktopId":"kitty"}]}');
                if (card.apps.length !== 1) throw new Error("App configuration failed");
                card.apply('bad json');
                if (card.apps.length !== 1) throw new Error("Invalid config lost previous data");
                card.opened = false;
                verifyClose.start();
            }
        }
        Timer {
            id: verifyClose; interval: 850
            onTriggered: {
                if (card.surfaceOpen || card.bloom > 0.01) throw new Error("Close animation failed");
                console.log("NOCTURNE_ARC_CHECK_PASSED");
                Qt.quit();
            }
        }
    }
}
