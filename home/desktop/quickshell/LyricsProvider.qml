import QtQuick
import Quickshell.Io
import "LyricsLogic.js" as LyricsLogic

QtObject {
    id: provider
    property var player: null
    property bool enabled: true
    property var lines: []
    property string status: "idle"
    property string requestKey: ""
    readonly property string trackKey: enabled && player ? JSON.stringify([
        player.dbusName || "", player.uniqueId, player.trackTitle, player.trackArtist,
        player.trackAlbum || "", player.lengthSupported ? player.length : 0]) : ""
    onTrackKeyChanged: {
        lines = [];
        status = trackKey ? "loading" : "idle";
        if (debounce) debounce.restart();
    }
    Component.onCompleted: debounce.restart()
    function reload() { status = trackKey ? "loading" : "idle"; debounce.restart(); }
    function fetch() {
        if (!trackKey || worker.running) return;
        requestKey = trackKey;
        worker.command = [Theme.lyricsCommand, "--title=" + String(player.trackTitle || ""),
            "--artist=" + String(player.trackArtist || ""), "--album=" + String(player.trackAlbum || ""),
            "--duration=" + String(player.lengthSupported ? player.length : 0)];
        worker.running = true;
    }
    property Timer debounce: Timer { interval: 250; onTriggered: provider.fetch() }
    property Process worker: Process {
        objectName: "lyrics-request"
        stdout: StdioCollector {
            onStreamFinished: {
                if (provider.requestKey !== provider.trackKey) return;
                try {
                    const value = JSON.parse(text);
                    if (!value || ["synced", "unsynced", "instrumental", "missing", "offline"].indexOf(value.status) < 0)
                        throw new Error("Invalid lyrics response");
                    provider.lines = value.status === "synced" ? LyricsLogic.parse(value.syncedLyrics) : [];
                    provider.status = value.status === "synced" && !provider.lines.length ? "unsynced" : value.status;
                } catch (e) { provider.lines = []; provider.status = "offline"; }
            }
        }
        onExited: { if (provider.requestKey !== provider.trackKey) provider.debounce.restart(); }
    }
}
