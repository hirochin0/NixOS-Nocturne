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

    PanelWindow {
        id: musicWindow
        screen: root.musicScreen
        visible: root.musicEnabled && !!root.player && !!root.musicScreen
        anchors { right: true; bottom: true }
        margins { right: 24; bottom: 24 }
        implicitWidth: Math.min(480, screen ? screen.width - 32 : 480)
        implicitHeight: 208
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "nocturne-music"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"
        MusicCard {
            anchors.fill: parent
            player: root.player
            updating: musicWindow.visible
        }
    }
    Variants {
        model: Quickshell.screens
        Taskbar {
            required property var modelData
            screen: modelData
            onPowerRequested: {
                powerMenu.screen = modelData;
                powerMenu.visible = !powerMenu.visible;
            }
        }
    }
    ClockWindow { screen: root.musicScreen }
    ArcLauncher {}
    PowerMenu { id: powerMenu; onDismissed: visible = false }
}
