{ pkgs, desktop, theme, user }:
let
  iconCatalog = pkgs.writeShellApplication {
    name = "nocturne-icon-catalog";
    runtimeInputs = [ pkgs.python3 ];
    text = ''exec python3 ${../home/scripts/icon_catalog.py}'';
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
      readonly property string font: ${builtins.toJSON theme.font}
      readonly property string iconCatalogCommand: "${iconCatalog}/bin/nocturne-icon-catalog"
      readonly property string iconIndexPath: "${iconIndex}"
      readonly property string barCommand: "${barTools}/bin/nocturne-bar"
      readonly property string batteryCommand: "${batteryTools}/bin/nocturne-battery"
      readonly property string musicOutput: ${builtins.toJSON (user.musicWidgetOutput or "")}
    }
  '';
in pkgs.runCommand "nocturne-quickshell-config" {
  nativeBuildInputs = [ desktop.qtdeclarative ];
} ''
  mkdir -p "$out"
  cp ${../home/desktop/quickshell}/*.qml "$out/"
  cp ${../home/desktop/quickshell}/*.js "$out/"
  cp ${../home/desktop/quickshell/launcher.svg} "$out/launcher.svg"
  cp ${../home/desktop/quickshell/launcher-defaults.json} "$out/launcher-defaults.json"
  cp ${../home/desktop/quickshell/application.svg} "$out/application.svg"
  cp ${palette} "$out/Theme.qml"
  cat > "$out/qmldir" <<'EOF'
  singleton Theme 1.0 Theme.qml
  ActionButton 1.0 ActionButton.qml
  MusicCard 1.0 MusicCard.qml
  PowerMenu 1.0 PowerMenu.qml
  PowerCard 1.0 PowerCard.qml
  singleton IconCatalog 1.0 IconCatalog.qml
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
