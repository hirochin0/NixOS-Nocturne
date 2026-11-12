{ pkgs, desktop, theme, user }:
let
  iconCatalog = pkgs.writeShellApplication {
    name = "nocturne-icon-catalog";
    runtimeInputs = [ pkgs.python3 ];
    text = ''exec python3 ${../home/scripts/icon_catalog.py}'';
  };
  lyricsTool = pkgs.writeShellApplication {
    name = "nocturne-lyrics";
    runtimeInputs = [ pkgs.python3 ];
    text = ''exec python3 ${../home/scripts/lyrics.py} "$@"'';
  };
  iconIndex = pkgs.runCommand "nocturne-icon-index" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python3 - <<'PYINDEX' > "$out"
    import json
    from pathlib import Path
    root = Path("${pkgs.papirus-icon-theme}/share/icons/Papirus/48x48/apps")
    print(json.dumps({p.stem: str(p) for p in root.glob("*.svg")}))
    PYINDEX
  '';
  barTools = import ./bar-tools.nix { inherit pkgs desktop; };
  batteryTools = import ./battery-tools.nix { inherit pkgs; };
  palette = pkgs.writeText "nocturne-quickshell-theme.qml" ''
    pragma Singleton
    import QtQuick
    QtObject {
      readonly property color bg: "#${theme.bg}"
      readonly property color surface: "#${theme.surface}"
      readonly property color elevated: "#${theme.elevated}"
      readonly property color text: "#${theme.text}"
      readonly property color muted: "#${theme.muted}"
      readonly property color cyan: "#${theme.cyan}"
      readonly property color green: "#${theme.green}"
      readonly property color yellow: "#${theme.yellow}"
      property FontLoader roundedFont: FontLoader {
        source: "${pkgs.nunito}/share/fonts/truetype/Nunito/Nunito[wght].ttf"
      }
      readonly property string wallpaperPath: "${theme.wallpaper}"
      readonly property string roundFont: roundedFont.name || "Nunito"
      readonly property string font: ${builtins.toJSON theme.font}
      readonly property string iconCatalogCommand: "${iconCatalog}/bin/nocturne-icon-catalog"
      readonly property string iconIndexPath: "${iconIndex}"
      readonly property string lyricsCommand: "${lyricsTool}/bin/nocturne-lyrics"
      readonly property string barCommand: "${barTools}/bin/nocturne-bar"
      readonly property string batteryCommand: "${batteryTools}/bin/nocturne-battery"
      readonly property string musicOutput: ${builtins.toJSON (user.musicWidgetOutput or "")}
    }
  '';
in pkgs.runCommand "nocturne-quickshell-config" {
  nativeBuildInputs = [ desktop.qtdeclarative desktop.qtshadertools ];
} ''
  mkdir -p "$out"
  cp ${../home/desktop/quickshell}/*.qml "$out/"
  cp ${../home/desktop/quickshell}/*.js "$out/"
  cp ${../home/desktop/quickshell/launcher.svg} "$out/launcher.svg"
  cp ${../home/desktop/quickshell/launcher-defaults.json} "$out/launcher-defaults.json"
  cp ${../home/desktop/quickshell/application.svg} "$out/application.svg"
  # Compile using the same Qt package set as Quickshell, including batchable vertices.
  qsb --batchable --glsl "100 es,120,150" --hlsl 50 --msl 12 \
    -o "$out/droplet.vert.qsb" ${../home/desktop/quickshell/droplet.vert}
  cp ${palette} "$out/Theme.qml"
  cat > "$out/qmldir" <<'EOF'
  singleton Theme 1.0 Theme.qml
  ActionButton 1.0 ActionButton.qml
  MusicCard 1.0 MusicCard.qml
  AlbumArt 1.0 AlbumArt.qml
  LyricsProvider 1.0 LyricsProvider.qml
  LyricsView 1.0 LyricsView.qml
  PowerMenu 1.0 PowerMenu.qml
  PowerCard 1.0 PowerCard.qml
  singleton IconCatalog 1.0 IconCatalog.qml
  GlassDigit 1.0 GlassDigit.qml
  GlassClock 1.0 GlassClock.qml
  ClockWindow 1.0 ClockWindow.qml
  DinoGame 1.0 DinoGame.qml
  DinoWindow 1.0 DinoWindow.qml
  singleton DinoScores 1.0 DinoScores.qml
  AppIcon 1.0 AppIcon.qml
  Taskbar 1.0 Taskbar.qml
  BarContent 1.0 BarContent.qml
  BarButton 1.0 BarButton.qml
  ArcLauncher 1.0 ArcLauncher.qml
  ArcLauncherCard 1.0 ArcLauncherCard.qml
  EOF
  export HOME="$TMPDIR/home" XDG_CACHE_HOME="$TMPDIR/cache" LANG=C.UTF-8
  mkdir -p "$HOME" "$XDG_CACHE_HOME"
  for file in "$out/"*.qml; do qmlformat --normalize "$file" > /dev/null; done
''
