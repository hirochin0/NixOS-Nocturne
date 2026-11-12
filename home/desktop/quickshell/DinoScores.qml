pragma Singleton
import QtCore
import Quickshell

Settings {
    location: "file://" + (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/nocturne/dino.ini"
    property int bestScore: 0
    function record(score) {
        if (!Number.isFinite(score) || score <= bestScore) return;
        bestScore = Math.floor(Math.min(score, 2147483647));
        setValue("bestScore", bestScore);
        sync();
    }
}
