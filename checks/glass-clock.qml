import QtQuick
import QtTest
import Quickshell
import "file://@bundle@"
ShellRoot {
    FloatingWindow {
        implicitWidth: 1040; implicitHeight: 540
        Item {
            id: surface
            anchors.fill: parent
            GlassClock { id: clock; anchors.centerIn: parent; width: 900; height: 360; ticking: false; now: new Date(2026, 10, 10, 16, 42) }
        }
        TestCase { id: interaction; name: "GlassClockInteraction"; when: false }
        Timer {
            interval: 400; running: true
            onTriggered: {
                function find(item, name) {
                    if (item.objectName === name) return item;
                    for (const child of item.children) { const result = find(child, name); if (result) return result; }
                    return null;
                }
                if (clock.timeText !== "16:42" || clock.dailyQuote.length < 5) throw new Error("Clock or quote missing");
                interaction.mouseMove(clock, 260, 180);
                interaction.wait(700);
                if (!clock.pointerActive) throw new Error("Clock hover did not activate");
                const digit = find(clock, "glass-digit-1");
                if (!digit || digit.tension < 0.1) throw new Error("Digit did not respond to cursor");
                interaction.mouseMove(surface, 2, 2);
                interaction.wait(1800);
                if (Math.abs(digit.tension) > 0.02) throw new Error("Digit did not return after pointer left");
                console.log("NOCTURNE_CLOCK_CHECK_PASSED");
                Qt.quit();
            }
        }
    }
}
