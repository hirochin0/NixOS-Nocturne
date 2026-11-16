import QtQuick
import QtTest
import Quickshell
import "file://@bundle@"
ShellRoot {
    FloatingWindow {
        implicitWidth: 640; implicitHeight: 400
        Item {
            id: surface; anchors.fill: parent
            property int restores: 0
            property int centerClicks: 0
            MouseArea { anchors.fill: parent; onClicked: surface.centerClicks++ }
            DesktopCurtain { id: curtain; anchors.fill: parent; onRestoreRequested: surface.restores++ }
        }
        TestCase { id: input; name: "DesktopCurtain"; when: false }
        Timer {
            interval: 350; running: true
            onTriggered: {
                for (const point of [[2, 200], [638, 200], [320, 2], [320, 398]]) input.mouseClick(curtain, point[0], point[1]);
                if (surface.restores !== 4) throw new Error("Curtain edge did not request restore");
                input.mouseClick(curtain, 320, 200);
                if (surface.centerClicks !== 0 || surface.restores !== 5) throw new Error("Center click did not restore or reached widget");
                console.log("NOCTURNE_DESKTOP_CURTAIN_CHECK_PASSED");
                Qt.quit();
            }
        }
    }
}
