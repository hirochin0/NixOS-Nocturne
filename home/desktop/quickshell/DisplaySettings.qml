import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: window
    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nocturne-display-settings"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    property var monitors: []
    property string token: ""
    property int remaining: 0
    property string error: ""
    property string notice: ""
    property string operation: ""
    property bool revertQueued: false

    function open() {
        if (visible) { close(); return; }
        if (worker.busy) return;
        const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        screen = Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0] || null;
        visible = true; notice = "";
        run("read");
    }
    function close() {
        visible = false;
        if (token || worker.busy) run("revert");
    }
    function run(action, args) {
        if (worker.busy) { if (action === "revert") revertQueued = true; return; }
        operation = action; error = "";
        worker.busy = true; worker.output = ""; worker.finished = false; worker.collected = false; worker.delivered = false;
        worker.command = [Theme.displayCommand, action].concat(args || []);
        worker.running = true;
        processTimeout.restart();
    }
    function edit(index, patch) {
        const next = monitors.slice();
        next[index] = Object.assign({}, next[index], patch);
        monitors = next; notice = "未適用の変更があります";
    }
    function receive(data) {
        if (!data.ok) { error = data.error || "設定を変更できませんでした"; return; }
        if (operation === "read") {
            monitors = data.monitors;
            if (card.selected >= monitors.length) card.selected = Math.max(0, monitors.length - 1);
            token = data.pending ? data.pending.token : "";
            remaining = data.pending ? data.pending.remaining : 0;
        } else if (operation === "preview") {
            token = data.token; remaining = data.remaining;
        } else {
            token = ""; remaining = 0;
            notice = operation === "confirm" ? "保存しました。再ログイン・モニター再接続後にも適用されます" : "元の設定に戻しました";
            if (visible) run("read");
        }
    }
    MouseArea { anchors.fill: parent; onClicked: window.close() }
    Item {
        anchors.fill: parent
        focus: window.visible
        Keys.onEscapePressed: window.close()
        DisplayCard {
            id: card
            anchors.centerIn: parent
            width: Math.min(960, parent.width - 32)
            height: Math.min(760, parent.height - 40)
            displays: window.monitors
            busy: worker.busy
            previewing: window.token.length > 0
            remaining: window.remaining
            error: window.error
            notice: window.notice
            onEditRequested: (index, patch) => window.edit(index, patch)
            onReloadRequested: window.run("read")
            onApplyRequested: window.run("preview", ["--plan=" + JSON.stringify(window.monitors)])
            onKeepRequested: window.run("confirm", ["--token=" + window.token])
            onRevertRequested: window.run("revert", ["--token=" + window.token])
            onCloseRequested: window.close()
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: window.token.length > 0
        onTriggered: {
            window.remaining = Math.max(0, window.remaining - 1);
            if (window.remaining === 0 && !worker.busy) {
                window.notice = "プレビューが終了しました";
                window.run("revert", ["--token=" + window.token]);
            }
        }
    }
    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (window.visible && (!window.screen || !Quickshell.screens.includes(window.screen)))
                window.screen = Quickshell.screens[0] || null;
            if (window.visible && !worker.busy && !window.token) window.run("read");
        }
    }
    Timer {
        id: processTimeout
        interval: 12000
        onTriggered: {
            window.error = "モニター設定の応答がありません。プレビューは自動で元に戻ります";
            window.revertQueued = true;
            if (worker.running) worker.signal(15);
        }
    }
    Process {
        id: worker
        property bool busy: false
        property string output: ""
        property bool finished: false
        property bool collected: false
        property bool delivered: false
        function deliver() {
            if (!finished || !collected || delivered) return;
            delivered = true;
            const result = output;
            Qt.callLater(function() {
                processTimeout.stop(); worker.busy = false;
                try { window.receive(JSON.parse(result)); }
                catch (e) { window.error = "モニター情報を取得できませんでした"; }
                if (window.revertQueued && !worker.busy) { window.revertQueued = false; window.run("revert"); }
            });
        }
        stdout: StdioCollector { onStreamFinished: { worker.output = text; worker.collected = true; worker.deliver(); } }
        onExited: { finished = true; deliver(); }
        onRunningChanged: if (!running && busy && !finished) failedStart.restart()
        property Timer failedStart: Timer {
            interval: 80
            onTriggered: if (!worker.running && worker.busy && !worker.finished) {
                processTimeout.stop(); worker.busy = false;
                window.error = "モニター設定プログラムを起動できませんでした";
            }
        }
    }
}
