import QtQuick
import QtTest
import Quickshell
import "file://@bundle@"
import "file://@bundle@/FocusLogic.js" as FocusLogic
ShellRoot {
    id: testRoot
    property var calls: []
    QtObject {
        id: testWorkspace
        property int id: 3
        property string name: "3"
        property bool focused: true
        property bool active: true
        function activate() { testRoot.calls.push("workspace"); }
    }
    QtObject {
        id: window
        property string title: "Editor test"
        // Same exposed shape as Quickshell 0.3.2 HyprlandToplevel:
        // no appId or activate() on the Hyprland object itself.
        property var lastIpcObject: ({class: "code", initialClass: "code"})
        property var workspace: testWorkspace
        property var wayland: waylandWindow
        property string address: "123abc"
        property bool activated: true

    }
    QtObject {
        id: waylandWindow
        property string appId: "code"
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
            workspaces: [testWorkspace]
            trayItems: []
            device: null
            status: ({network: "󰖩 80%", networkDetail: "Test Wi-Fi", audio: "󰕾 50%", brightness: "70%", calendar: "Calendar"})
            function dispatch(request) { testRoot.calls.push("dispatch:" + request); }
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
                IconCatalog.entries = [
                    {id: "files", name: "", startupClass: "", icon: "system-file-manager"},
                    {id: "kitty", name: "Kitty", startupClass: "kitty", icon: "kitty"},
                    {id: "google-chrome", name: "Chrome", startupClass: "Google-chrome", icon: "google-chrome"},
                    {id: "chatgpt", name: "ChatGPT", startupClass: "chrome-chatgpt.com__-Default", icon: "google-chrome"}
                ];
                for (const appClass of ["kitty", "google-chrome", "chrome-chatgpt.com__-Default"]) {
                    const nativeShape = {lastIpcObject: {class: appClass}, wayland: null};
                    if (bar.appIdFor(nativeShape) !== appClass) throw new Error("Native Hyprland class not extracted");
                    const entry = bar.desktopFor(nativeShape);
                    if (!entry || entry.id === "files") throw new Error("Window incorrectly matched to Files: " + appClass);
                }
                if (bar.desktopFor({lastIpcObject: {}, wayland: null}) !== null)
                    throw new Error("Empty class must not match Files");
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
                for (const appId of ["google-chrome", "kitty", "chrome-chatgpt.com__-Default"]) {
                    icon.iconName = appId;
                    interaction.wait(100);
                    if (icon.status !== 1 || String(icon.source).indexOf("application.svg") !== -1)
                        throw new Error("Observed app class icon missing: " + appId);
                }
                icon.destroy();
                const task = find(bar, "task-code");
                if (!task) throw new Error("Window button missing");
                interaction.mouseClick(task, task.width / 2, task.height / 2);
                if (testRoot.calls.length !== 1 || testRoot.calls[0] !== "dispatch:" + FocusLogic.request("123abc", false))
                    throw new Error("Addressed window did not use compositor dispatch even with a Wayland handle");
                if (FocusLogic.request("0xabcdef", true) !== 'hl.dsp.focus({ window = "address:0xabcdef" })')
                    throw new Error("Lua dispatcher syntax incorrect");
                for (const invalid of ["", "0", "0x0", "bad; command", "../window"])
                    if (FocusLogic.request(invalid, true)) throw new Error("Invalid address accepted");
                testRoot.calls = [];
                bar.focusWindow({workspace: testWorkspace, wayland: null, address: "abcdef"});
                if (testRoot.calls.length !== 1 || !testRoot.calls[0].includes("address:0xabcdef"))
                    throw new Error("IPC-only window focus failed");
                testRoot.calls = [];
                bar.focusWindow({workspace: testWorkspace, wayland: waylandWindow, address: ""});
                if (JSON.stringify(testRoot.calls) !== '["workspace","window"]') throw new Error("Unmapped window fallback failed");
                bar.windows = [];
                if (bar.windows.length !== 0) throw new Error("Closed window not removed");
                bar.workspaces = [];
                console.log("NOCTURNE_TASKBAR_CHECK_PASSED");
                Qt.quit();
            }
        }
    }
}
