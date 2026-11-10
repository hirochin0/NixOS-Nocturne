import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: window
    anchors.top: true
    margins.top: Math.max(70, screen ? screen.height * 0.37 - implicitHeight / 2 : 160)
    implicitWidth: Math.min(900, screen ? screen.width - 40 : 900)
    implicitHeight: 360
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "nocturne-glass-clock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
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
        anchors.fill: parent
        desktopWidth: window.screen ? window.screen.width : width
        desktopHeight: window.screen ? window.screen.height : height
        desktopX: (desktopWidth - width) / 2
        desktopY: window.margins.top
    }
}
