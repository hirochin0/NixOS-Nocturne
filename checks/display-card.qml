import QtQuick
import QtQuick.Controls
import QtTest
import Quickshell
import "file://@bundle@"
ShellRoot {
    FloatingWindow {
        implicitWidth: 1000; implicitHeight: 800
        DisplayCard {
            id: card
            anchors.fill: parent
            property int edits: 0
            property int applies: 0
            displays: [
                {name:"eDP-1",description:"Internal",mode:"1920x1080@60.000",x:0,y:0,scale:1,transform:0,internal:true,availableModes:["1920x1080@60.00Hz"]},
                {name:"HDMI-A-1",description:"External",mode:"1920x1080@60.000",x:1920,y:0,scale:1,transform:0,availableModes:["1920x1080@60.00Hz","1920x1080@120.00Hz","1280x720@59.94Hz"]}
            ]
            onEditRequested: (i, patch) => {
                const next = displays.slice(); next[i] = Object.assign({},next[i],patch); displays = next; edits++;
            }
            onApplyRequested: { applies++; previewing = true; remaining = 15; }
        }
        TestCase { id: input; name: "DisplayCard"; when: false }
        Timer {
            interval: 400; running: true
            onTriggered: {
                card.selected = 1;
                const refresh = input.findChild(card, "display-refresh");
                refresh.currentIndex = 0; refresh.activated(0);
                if (card.displays[1].mode !== "1920x1080@120.000" || card.edits !== 1) throw new Error("Hz selection did not edit selected monitor");
                const resolution = input.findChild(card, "display-resolution");
                resolution.currentIndex = 1; resolution.activated(1);
                if (card.displays[1].mode !== "1280x720@59.940") throw new Error("Resolution selection lost fractional refresh rate");
                const apply = input.findChild(card, "display-apply");
                input.mouseClick(apply, apply.width / 2, apply.height / 2);
                if (card.applies !== 1 || !card.previewing) throw new Error("Apply did not start preview");
                console.log("NOCTURNE_DISPLAY_CARD_CHECK_PASSED");
                Qt.quit();
            }
        }
    }
}
