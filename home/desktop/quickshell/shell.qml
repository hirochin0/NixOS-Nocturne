import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "Logic.js" as Logic

ShellRoot {
    id: root
    property bool musicEnabled: true
    readonly property var player: Logic.spotifyPlayer(Mpris.players.values)
    readonly property var musicScreen: Logic.musicScreen(Quickshell.screens, Theme.musicOutput)

    IpcHandler {
        target: "widgets"
        function toggleMusic(): void { root.musicEnabled = !root.musicEnabled; }
        function togglePower(): void {
            if (powerMenu.visible) {
                powerMenu.visible = false;
            } else {
                var name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
                powerMenu.screen = Quickshell.screens.find(function(s) { return s.name === name; })
                    || root.musicScreen;
                powerMenu.visible = true;
            }
        }
    }

    DesktopController { id: desktop }
    IpcHandler {
        target: "desktop"
        function show(): void { desktop.show(); }
        function hide(): void { desktop.hide(); }
        function toggle(): void { desktop.toggle(); }
    }
    LyricsProvider { id: lyrics; player: root.player; enabled: root.musicEnabled }
    Timer {
        interval: 250
        repeat: true
        running: root.musicEnabled && !!root.player && root.player.isPlaying && root.player.positionSupported
        onTriggered: root.player.positionChanged()
    }
    Variants {
        model: Quickshell.screens
        Taskbar {
            required property var modelData
            screen: modelData
            musicPlayer: root.player
            onPowerRequested: {
                powerMenu.screen = modelData;
                powerMenu.visible = !powerMenu.visible;
            }
        }
    }
    Variants {
        model: Quickshell.screens
        ClockWindow {
            required property var modelData
            screen: modelData
            player: root.player
            musicEnabled: root.musicEnabled && Logic.musicScreens(Quickshell.screens, Theme.musicOutput).indexOf(modelData) >= 0
            lyricLines: lyrics.lines
            lyricStatus: lyrics.status
            onLyricsRetryRequested: lyrics.reload()
        }
    }
    Variants {
        model: Quickshell.screens
        ArcLauncher {
            required property var modelData
            screen: modelData
        }
    }
    Variants {
        model: Quickshell.screens
        DinoWindow {
            required property var modelData
            screen: modelData
        }
    }
    PowerMenu { id: powerMenu; onDismissed: visible = false }
}
