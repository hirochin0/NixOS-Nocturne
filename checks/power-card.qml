import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.UPower
import "file://@bundle@"

ShellRoot {
    FloatingWindow {
        implicitWidth: 420
        implicitHeight: 440
        PowerCard {
            id: card
            anchors.centerIn: parent
            width: 360
            height: implicitHeight
            device: mock
            onBattery: true
            onPercentageRequested: value => showPercentage = value
        }
        QtObject {
            id: mock
            property bool ready: true
            property bool isPresent: true
            property real percentage: 0.65
            property int state: UPowerDeviceState.Discharging
            property real timeToEmpty: 9000
            property real timeToFull: 0
        }
        TestCase { id: interaction; name: "PowerCardInteraction"; when: false }
        Timer {
            interval: 100
            running: true
            onTriggered: {
                var menuComponent = Qt.createComponent("file://@bundle@/PowerMenu.qml");
                // The offscreen test platform cannot provide Wayland layer-shell windows.
                if (menuComponent.status !== Component.Ready
                        && menuComponent.errorString().indexOf("No PanelWindow backend loaded") === -1)
                    throw new Error(menuComponent.errorString());
        function findSwitch(item) {
            if (item.objectName === "batteryPercentageSwitch") return item;
            for (var i = 0; i < item.children.length; ++i) {
                var found = findSwitch(item.children[i]);
                if (found) return found;
            }
            return null;
        }
                var toggle = findSwitch(card);
                if (!toggle) throw new Error("Percentage switch not found");
                interaction.mouseClick(toggle, toggle.width / 2, toggle.height / 2);
                if (card.showPercentage) throw new Error("Percentage switch did not turn off");
                interaction.mouseClick(toggle, toggle.width / 2, toggle.height / 2);
                if (!card.showPercentage) throw new Error("Percentage switch did not turn back on");
                if (card.percentageText !== "65%" || card.estimateText !== "2 h 30 min remaining")
                    throw new Error("Discharging estimate or UPower percentage scale is wrong");
                mock.timeToEmpty = 0;
                Qt.callLater(function() {
                    if (card.estimateText !== "Estimating remaining time…") throw new Error("Unknown time was not handled");
                    card.onBattery = false;
                    mock.state = UPowerDeviceState.Charging;
                    mock.timeToFull = 3600;
                    Qt.callLater(function() {
                        if (card.estimateText !== "1 h until full") throw new Error("Charging estimate is wrong");
                        mock.state = UPowerDeviceState.FullyCharged;
                        Qt.callLater(function() {
                            if (card.estimateText !== "Fully charged") throw new Error("Full state is wrong");
                            card.device = null;
                            Qt.callLater(function() {
                                if (card.percentageText !== "—" || card.estimateText !== "Calculating remaining time…")
                                    throw new Error("Missing battery left stale data");
                                console.log("NOCTURNE_POWER_CARD_CHECK_PASSED");
                                Qt.quit();
                            });
                        });
                    });
                });
            }
        }
    }
}
