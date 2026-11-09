import QtQuick
import Quickshell
import "file://@bundle@"
ShellRoot {
    FloatingWindow {
        implicitWidth: 352; implicitHeight: 352
        ArcLauncherCard { id: card; anchors.fill: parent }
        Timer {
            interval: 850; running: true
            onTriggered: {
                if (card.apps.length !== 6) throw new Error("Default app list not loaded");
                card.opened = true;
                verifyOpen.start();
            }
        }
        Timer {
            id: verifyOpen; interval: 850
            onTriggered: {
                if (!card.surfaceOpen || card.bloom < 0.99) throw new Error("Open animation failed");
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
