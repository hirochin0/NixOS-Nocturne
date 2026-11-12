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
    property int prepareAttempts: 0
    property var queuedRequest: null
    function run(action, args) {
        if (worker.busy) {
            if (action !== "state") queuedRequest = {action: action, args: args || []};
            return;
        }
        queuedRequest = null;
        worker.output = ""; worker.outputComplete = false; worker.finishedFlag = false; worker.delivered = false;
        worker.busy = true;
        watchdog.restart();
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
        if (["idle", "recovery", "cleanup", "return", "restoring"].indexOf(phase) >= 0) return;
        if (["inspect", "preparing", "capture"].indexOf(phase) >= 0) {
            prepare.stop(); scene.reset(); phase = "cleanup";
            if (!worker.busy) run("restore", plan ? ["--token=" + plan.token] : []);
            return;
        }
        if (phase === "showing") { pendingHide = true; return; }
        watch.stop();
        if (phase === "settling") {
            settle.stop(); phase = "return";
            run("restore", ["--token=" + plan.token]); return;
        }
        phase = "return"; scene.returnWindows();
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
            prepareAttempts = 0; phase = "preparing"; prepare.restart();
        } else if (operation === "show") {
            if (pendingHide) { phase = "return"; run("restore", ["--token=" + plan.token]); return; }
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
    function backendFailure(message) {
        watchdog.stop(); worker.busy = false;
        if (operation === "restore" || operation === "recover") {
            console.warn("Desktop recovery:", message);
            scene.reset(); phase = "recovery"; recovery.restart();
        } else fail(message);
    }
    function finish() {
        watch.stop(); settle.stop(); prepare.stop(); recovery.stop(); watchdog.stop(); scene.reset();
        queuedRequest = null; plan = null; phase = "idle"; pendingHide = false; restoreFocus = true;
    }
    Component.onCompleted: run("recover")
    Component.onDestruction: {
        if (plan) Quickshell.execDetached([Theme.desktopCommand, "restore", "--token=" + plan.token]);
    }
    Timer { id: recovery; interval: 2000; onTriggered: if (!worker.busy) controller.run("recover") }
    Timer {
        id: prepare; interval: 60
        onTriggered: {
            scene.plan = controller.plan;
            scene.snapshots = DesktopLogic.windows(controller.plan, Hyprland.toplevels.values);
            if (scene.snapshots.some(w => !w.source) && controller.prepareAttempts++ < 5) { prepare.restart(); return; }
            scene.snapshots = scene.snapshots.filter(w => w.width > 0 && w.height > 0);
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
    Timer {
        id: watchdog
        interval: 20000
        onTriggered: {
            if (worker.running) {
                controller.fail("Desktop helper timed out; restoring workspace");
                worker.signal(15);
            } else controller.backendFailure("Desktop helper did not finish");
        }
    }
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
                watchdog.stop();
                worker.busy = false;
                try { controller.receive(JSON.parse(value)); }
                catch (e) { controller.backendFailure("Desktop helper returned no result"); }
                if (!worker.busy && controller.queuedRequest) {
                    const request = controller.queuedRequest;
                    controller.run(request.action, request.args);
                }
            });
        }
        stdout: StdioCollector {
            onStreamFinished: { worker.output = text; worker.outputComplete = true; worker.deliver(); }
        }
        onStarted: { output = ""; outputComplete = false; finishedFlag = false; delivered = false; }
        onExited: { finishedFlag = true; deliver(); }
        onRunningChanged: if (!running && busy && !finishedFlag) processStopped.restart()
        property Timer processStopped: Timer {
            interval: 80
            onTriggered: if (!worker.running && worker.busy && !worker.finishedFlag) {
                controller.backendFailure("Desktop helper could not start");
            }
        }
    }
    DesktopScene {
        id: scene
        onCaptured: { controller.phase = "showing"; controller.run("show", ["--plan=" + JSON.stringify(controller.plan)]); }
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
