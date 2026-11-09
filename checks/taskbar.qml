import QtQuick
import QtTest
import Quickshell
import "file://@bundle@"
ShellRoot {
    id: testRoot
    property var calls: []
    QtObject {
        id: workspace
        property int id: 3
        property string name: "3"
        property bool focused: true
        property bool active: true
        function activate() { testRoot.calls.push("workspace"); }
    }
    QtObject {
        id: window
        property string title: "Editor test"
        property string appId: "code"
        property bool activated: true
        function activate() { testRoot.calls.push("window"); }
    }
    FloatingWindow {
        implicitWidth: 1440; implicitHeight: 60
        BarContent {
            id: bar
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 46
            live: false
            windows: [window]
            workspaces: [workspace]
            trayItems: []
            device: null
            status: ({network: "󰖩 80%", networkDetail: "Test Wi-Fi", audio: "󰕾 50%", brightness: "70%", calendar: "Calendar"})
            function workspaceFor(w) { return workspace; }
        }
        TestCase { id: interaction; name: "TaskbarInteraction"; when: false }
        Timer {
            interval: 350; running: true
            onTriggered: {
                function find(item, name) {
                    if (item.objectName === name) return item;
                    for (const child of item.children) { const result = find(child, name); if (result) return result; }
                    return null;
                }
                const clock = find(bar, "clockIsland");
                if (!clock || Math.abs(clock.x + clock.width / 2 - bar.width / 2) > 0.5)
                    throw new Error("Clock is not at screen center");
                const iconComponent = Qt.createComponent("file://@bundle@/AppIcon.qml");
                if (iconComponent.status !== Component.Ready) throw new Error(iconComponent.errorString());
                const icon = iconComponent.createObject(bar, {iconName: "no-such-icon-nocturne", width: 28, height: 28});
                if (String(icon.source).indexOf("application.svg") === -1) throw new Error("Missing icon fallback failed");
                icon.iconName = "/does-not-exist-nocturne.png";
                interaction.wait(120);
                if (String(icon.source).indexOf("application.svg") === -1) throw new Error("Failed path did not recover");
                icon.iconName = "spotify";
                interaction.wait(120);
                if (String(icon.source).indexOf("application.svg") !== -1 || icon.status !== 1)
                    throw new Error("Valid icon did not replace fallback");
                icon.destroy();
                const task = find(bar, "task-code");
                if (!task) throw new Error("Window button missing");
                interaction.mouseClick(task, task.width / 2, task.height / 2);
                if (JSON.stringify(testRoot.calls) !== '["workspace","window"]') throw new Error("Focus did not switch workspace first");
                bar.windows = [];
                if (bar.windows.length !== 0) throw new Error("Closed window not removed");
                bar.workspaces = [];
                console.log("NOCTURNE_TASKBAR_CHECK_PASSED");
                Qt.quit();
            }
        }
    }
}
