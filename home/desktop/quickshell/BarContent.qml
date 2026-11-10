import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import "BatteryLogic.js" as BatteryLogic
import "IconLogic.js" as IconLogic
import "FocusLogic.js" as FocusLogic

Item {
    id: root
    property var hostWindow: null
    property var windows: Hyprland.toplevels.values
    property var workspaces: Hyprland.workspaces.values
    property var trayItems: SystemTray.items.values
    property var device: UPower.displayDevice
    property bool live: true
    property bool showPercentage: true
    property var status: ({network: "󰖪 —", audio: "󰕾 —", brightness: "—", calendar: ""})
    property date now: new Date()
    signal powerRequested()
    function action(name) { Quickshell.execDetached([Theme.barCommand, name]); }
    function workspaceFor(window) { return window.workspace || null; }
    function dispatch(request) { Hyprland.dispatch(request); }
    function focusWindow(window) {
        // A compositor address selects the exact window, including windows on
        // other workspaces. Avoid the serial/activation rules of foreign-toplevel.
        const request = FocusLogic.request(window.address, Hyprland.usingLua);
        if (request) {
            root.dispatch(request);
            return;
        }
        // A newly mapped window can temporarily lack its Hyprland address.
        const workspace = workspaceFor(window);
        if (workspace) workspace.activate();
        if (window.wayland) window.wayland.activate();
        else console.warn("Taskbar: window has no address or activation handle");
    }
    function switchWorkspace(id) {
        const workspace = workspaces.find(w => w.id === id);
        if (workspace) workspace.activate();
        else Hyprland.dispatch(Hyprland.usingLua ? 'hl.dsp.focus({ workspace = "' + id + '" })' : "workspace " + id);
    }
    function appIdFor(window) {
        const ipc = window.lastIpcObject;
        return (ipc && (ipc.class || ipc.initialClass)) || (window.wayland && window.wayland.appId) || "";
    }
    function desktopFor(window) {
        const appId = appIdFor(window);
        return IconLogic.findEntry(appId, IconCatalog.entries)
            || IconLogic.findEntry(appId, DesktopEntries.applications.values);
    }
    readonly property var workspaceIds: {
        const ids = [1, 2, 3, 4, 5];
        for (const workspace of workspaces) if (!ids.includes(workspace.id)) ids.push(workspace.id);
        return ids;
    }
    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/nocturne/battery.json"
        watchChanges: true; printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { const data = JSON.parse(text()); root.showPercentage = data.showPercentage !== false; }
            catch (e) { root.showPercentage = true; }
        }
    }
    Process {
        id: reader
        command: [Theme.barCommand, "status"]
        running: root.live
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.status = JSON.parse(text); } catch (e) { console.warn("Bar status unavailable"); }
            }
        }
    }
    Timer { interval: 2000; repeat: true; running: root.live; onTriggered: if (!reader.running) reader.running = true }
    Timer { interval: 1000; repeat: true; running: root.live; onTriggered: root.now = new Date() }
    RowLayout {
        anchors { left: parent.left; right: parent.horizontalCenter; top: parent.top; bottom: parent.bottom }
        spacing: 8
        Rectangle {
            Layout.preferredWidth: leftRow.implicitWidth + 12
            Layout.fillHeight: true
            radius: height / 2; color: Qt.alpha(Theme.bg, 0.94); border.color: Theme.elevated
            Row {
                id: leftRow
                anchors.centerIn: parent; spacing: 2
                BarButton { labelSize: 32; labelFont: Theme.font; labelWeight: Font.Normal; implicitWidth: 52; text: "󱄅"; tint: Theme.cyan; hint: "Applications"; onClicked: root.action("launcher") }
                Repeater {
                    model: root.workspaceIds
                    BarButton {
                        required property int modelData
                        readonly property var workspace: root.workspaces.find(w => w.id === modelData)
                        text: workspace ? workspace.name : String(modelData)
                        tint: workspace && workspace.urgent ? "#f38ba8" : workspace && workspace.focused ? Theme.cyan : Theme.muted
                        hint: "Workspace " + text
                        onClicked: root.switchWorkspace(modelData)
                        Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: 14; height: 2; radius: 1; color: Theme.cyan; visible: !!parent.workspace && parent.workspace.active }
                    }
                }
            }
        }
    }
    Rectangle {
        id: clockIsland
        objectName: "clockIsland"
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.height
        width: clock.implicitWidth + 20
        radius: height / 2; color: Qt.alpha(Theme.bg, 0.94); border.color: Theme.elevated
        BarButton {
            id: clock
            anchors.fill: parent
            text: Qt.formatDateTime(root.now, "ddd  MM.dd  ·  HH:mm")
            hint: root.status.calendar || Qt.formatDate(root.now, "yyyy-MM-dd")
        }
    }
    RowLayout {
        id: rightGroup
        anchors { left: clockIsland.right; leftMargin: 12; right: parent.right; top: parent.top; bottom: parent.bottom }
        spacing: 8
        Item { Layout.fillWidth: true }
        Rectangle {
            Layout.preferredWidth: Math.min(root.windows.length * 36 + 12, Math.max(42, rightGroup.width - statusRow.implicitWidth - 28))
            Layout.minimumWidth: root.windows.length ? 48 : 0
            Layout.fillHeight: true
            visible: root.windows.length > 0
            radius: height / 2; color: Qt.alpha(Theme.bg, 0.94); border.color: Theme.elevated
            Flickable {
                id: tasks
                anchors.fill: parent; anchors.margins: 5
                clip: true; contentWidth: taskRow.implicitWidth; contentHeight: height
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick
                Row {
                    id: taskRow
                    spacing: 2
                    Repeater {
                        model: root.windows
                        BarButton {
                            id: task
                            required property var modelData
                            objectName: "task-" + root.appIdFor(modelData)
                            readonly property var desktop: root.desktopFor(modelData)
                            readonly property var workspace: root.workspaceFor(modelData)
                            implicitWidth: 34; implicitHeight: 34
                            hint: modelData.title + (workspace ? " · Workspace " + workspace.name : "")
                            tint: modelData.activated ? Theme.cyan : Theme.muted
                            onClicked: root.focusWindow(modelData)
                            onScrolled: up => tasks.contentX = Math.max(0, Math.min(tasks.contentWidth - tasks.width, tasks.contentX + (up ? -80 : 80)))
                            background: Rectangle {
                                radius: height / 2
                                color: task.hovered ? Theme.elevated : task.modelData.activated ? Qt.alpha(Theme.cyan, 0.12) : "transparent"
                            }
                            contentItem: Item {
                                AppIcon { anchors.centerIn: parent; width: 28; height: 28; iconName: task.desktop && task.desktop.icon ? task.desktop.icon : root.appIdFor(task.modelData) }
                                Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: 12; height: 2; radius: 1; color: Theme.cyan; visible: task.modelData.activated }
                            }
                        }
                    }
                }
            }
        }
        Rectangle {
            Layout.preferredWidth: Math.min(statusRow.implicitWidth + 12, Math.max(0, rightGroup.width - (root.windows.length ? 54 : 0)))
            Layout.minimumWidth: 0
            clip: true
            Layout.fillHeight: true
            radius: height / 2; color: Qt.alpha(Theme.bg, 0.94); border.color: Theme.elevated
            Row {
                id: statusRow
                anchors.centerIn: parent; spacing: 1
                BarButton { text: root.status.network; hint: root.status.networkDetail || "Network"; tint: Theme.cyan; onClicked: root.action("network") }
                BarButton {
                    text: root.status.audio; hint: "Volume · scroll to adjust · right click to mute"
                    onClicked: root.action("audio"); onSecondaryClicked: root.action("mute")
                    onScrolled: up => root.action(up ? "volume-up" : "volume-down")
                }
                BarButton { text: "󰃠 " + root.status.brightness; tint: Theme.yellow; hint: "Brightness · scroll to adjust"; onScrolled: up => root.action(up ? "brightness-up" : "brightness-down") }
                BarButton {
                    id: battery
                    readonly property bool ready: !!root.device && root.device.ready && root.device.isPresent
                    readonly property real charge: ready ? Math.max(0, Math.min(1, root.device.percentage)) : 0
                    visible: ready
                    implicitWidth: batteryRow.implicitWidth + 16
                    hint: ready ? BatteryLogic.estimate(true, true, root.device.state === UPowerDeviceState.Discharging,
                        root.device.state === UPowerDeviceState.Charging, root.device.state === UPowerDeviceState.FullyCharged,
                        root.device.timeToEmpty, root.device.timeToFull) : "Battery"
                    onClicked: root.powerRequested()
                    contentItem: Row {
                        id: batteryRow
                        spacing: 7
                        Rectangle {
                            width: 27; height: 14; radius: 3
                            anchors.verticalCenter: parent.verticalCenter
                            color: "transparent"; border.color: battery.charge < 0.15 ? "#f38ba8" : Theme.text
                            Rectangle { x: 3; y: 3; height: 8; width: 21 * battery.charge; radius: 1; color: root.device && root.device.state === UPowerDeviceState.Charging ? Theme.green : battery.charge < 0.15 ? "#f38ba8" : Theme.cyan }
                            Rectangle { x: 27; y: 4; width: 2; height: 6; radius: 1; color: Theme.muted }
                        }
                        Text { visible: root.showPercentage; text: Math.round(battery.charge * 100) + "%"; color: Theme.text; font { family: Theme.roundFont; pixelSize: 13; weight: Font.Bold; variableAxes: ({"wght": 800}) } }
                    }
                }
                Repeater {
                    model: root.trayItems
                    BarButton {
                        id: trayButton
                        required property var modelData
                        implicitWidth: 30
                        hint: modelData.tooltipTitle || modelData.title || modelData.id
                        contentItem: Image { source: trayButton.modelData.icon; sourceSize.width: 20; sourceSize.height: 20; fillMode: Image.PreserveAspectFit }
                        function menu() { if (root.hostWindow && modelData.hasMenu) { const p = mapToItem(root, 0, height); modelData.display(root.hostWindow, p.x, p.y); } }
                        onClicked: { if (modelData.onlyMenu) menu(); else modelData.activate(); }
                        onSecondaryClicked: menu()
                        onScrolled: up => modelData.scroll(up ? 120 : -120, false)
                    }
                }
                BarButton { text: "󰐥"; tint: Theme.cyan; hint: "Session"; onClicked: root.action("session") }
            }
        }

    }
}
