import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: window
    property var player: null
    property bool musicEnabled: false
    property var lyricLines: []
    property string lyricStatus: "idle"
    signal lyricsRetryRequested()
    anchors.top: true
    margins.top: Math.max(70, screen ? screen.height * 0.37 - 180 : 160)
    implicitWidth: Math.min(900, screen ? screen.width - 40 : 900)
    implicitHeight: music.visible ? Math.max(360, music.y + music.height) : 360
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "nocturne-glass-clock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: clock; Region { item: music.visible ? music : null } }
    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/nocturne/wallpaper.json"
        watchChanges: true; printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { const value = JSON.parse(text()); if (value.image) clock.wallpaperSource = value.image; } catch (e) {}
        }
    }
    GlassClock {
        id: clock
        width: parent.width
        height: 360
        desktopWidth: window.screen ? window.screen.width : width
        desktopHeight: window.screen ? window.screen.height : height
        desktopX: (desktopWidth - width) / 2
        desktopY: window.margins.top
    }
    MusicCard {
        id: music
        objectName: "clock-music"
        x: (parent.width - width) / 2
        y: clock.quoteBottom + 16
        width: Math.min(640, parent.width - 40)
        height: Math.max(170, Math.min(280, window.screen ? window.screen.height - window.margins.top - y - 16 : 280))
        visible: window.musicEnabled && !!window.player
        player: window.player
        updating: visible
        lyricLines: window.lyricLines
        lyricStatus: window.lyricStatus
        onLyricsRetryRequested: window.lyricsRetryRequested()
    }
}
