import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "DesktopLogic.js" as DesktopLogic

Scope {
    id: controller
    property string phase: "recovery"
    property string operation: "recover"
    property var plan: null
    property bool pendingHide: false
    property bool restoreFocus: true
    function run(action, args) {
        if (worker.busy) return;
        worker.busy = true;
        operation = action;
        worker.command = [Theme.desktopCommand, action === "recover" ? "restore" : action].concat(args || []);
        worker.running = true;
    }
    function show() {
        if (phase !== "idle" || worker.busy) return;
        phase = "inspect"; pendingHide = false;
        run("inspect");
    }
    function hide() {
        if (phase === "idle" || phase === "recovery") return;
        if (phase !== "desktop") { pendingHide = true; return; }
        watch.stop(); phase = "return";
        scene.returnWindows();
    }
    function toggle() { if (phase === "idle") show(); else hide(); }
    function fail(message) {
        console.warn("Desktop reveal:", message);
        Quickshell.execDetached([Theme.notificationCommand, "--app-name=NOCTURNE", "Desktop view unavailable", message]);
        watch.stop(); settle.stop(); prepare.stop(); scene.reset();
        phase = "cleanup";
        if (!worker.busy) run("restore", plan ? ["--token=" + plan.token] : []);
    }
    function receive(data) {
        if (phase === "cleanup" && operation !== "restore" && operation !== "recover") {
            run("restore", plan ? ["--token=" + plan.token] : []); return;
        }
        if (operation === "recover" || operation === "restore") {
            if (data.ok === false) { phase = "recovery"; recovery.restart(); return; }
            if (operation === "restore" && scene.frozenBackground && restoreFocus) {
                phase = "restoring"; settle.interval = plan ? plan.settleMs : 750; settle.restart();
            } else finish();
        } else if (data.ok === false) fail(data.error || "backend failed");
        else if (operation === "inspect") {
            plan = data;
            scene.screen = Quickshell.screens.find(s => s.name === data.monitor) || null;
            if (!scene.screen) { fail("Monitor disconnected"); return; }
            Hyprland.refreshToplevels();
            phase = "preparing"; prepare.restart();
        } else if (operation === "show") {
            phase = "settling";
            settle.interval = plan.settleMs; settle.restart();
        } else if (operation === "state") {
            if (!data.active || data.opened) {
                watch.stop(); restoreFocus = !!data.active;
                phase = "cleanup"; scene.frozenBackground = false;
                run("restore", ["--token=" + plan.token].concat(restoreFocus ? [] : ["--no-focus"]));
            }
        }
    }
    function finish() {
        watch.stop(); settle.stop(); prepare.stop(); recovery.stop(); scene.reset();
        plan = null; phase = "idle"; pendingHide = false; restoreFocus = true;
    }
    Component.onCompleted: run("recover")
    Component.onDestruction: {
        if (plan) Quickshell.execDetached([Theme.desktopCommand, "restore", "--token=" + plan.token]);
    }
    Timer { id: recovery; interval: 2000; onTriggered: if (!worker.busy) controller.run("recover") }
    Timer {
        id: prepare; interval: 180
        onTriggered: {
            scene.plan = controller.plan;
            scene.snapshots = DesktopLogic.windows(controller.plan, Hyprland.toplevels.values);
            if (scene.snapshots.some(w => !w.source || w.width <= 0 || w.height <= 0)) { controller.fail("Window capture handle unavailable"); return; }
            controller.phase = "capture";
            scene.capture();
        }
    }
    Timer {
        id: settle
        onTriggered: {
            if (controller.phase === "restoring") controller.finish();
            else { controller.phase = "retreat"; scene.retreat(); }
        }
    }
    Timer { id: watch; interval: 700; repeat: true; onTriggered: if (!worker.busy) controller.run("state", ["--token=" + controller.plan.token]) }
    Process {
        id: worker
        objectName: "desktop-helper"
        property string output: ""
        property bool busy: false
        property bool outputComplete: false
        property bool finishedFlag: false
        property bool delivered: false
        function deliver() {
            if (!outputComplete || !finishedFlag || delivered) return;
            delivered = true;
            const value = output;
            Qt.callLater(function() {
                worker.busy = false;
                try { controller.receive(JSON.parse(value)); }
                catch (e) { controller.fail("Desktop helper returned no result"); }
            });
        }
        stdout: StdioCollector {
            onStreamFinished: { worker.output = text; worker.outputComplete = true; worker.deliver(); }
        }
        onStarted: { output = ""; outputComplete = false; finishedFlag = false; delivered = false; }
        onExited: { finishedFlag = true; deliver(); }
    }
    DesktopScene {
        id: scene
        onCaptured: controller.run("show", ["--plan=" + JSON.stringify(controller.plan)])
        onCaptureFailed: controller.fail("Window capture timed out; original workspace retained")
        onRetreated: {
            controller.phase = "desktop"; watch.start();
            if (controller.pendingHide) controller.hide();
        }
        onReturned: controller.run("restore", ["--token=" + controller.plan.token])
        onRestoreRequested: controller.hide()
        onScreenChanged: if (controller.plan && (!screen || screen.name !== controller.plan.monitor)) controller.fail("Monitor disconnected")
    }
}
