{ pkgs, desktop, theme, user }:
let
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
      readonly property string musicOutput: ${builtins.toJSON (user.musicWidgetOutput or "")}
    }
  '';
in pkgs.runCommand "nocturne-quickshell-config" {
  nativeBuildInputs = [ desktop.qtdeclarative ];
} ''
  mkdir -p "$out"
  cp ${../home/desktop/quickshell}/*.qml "$out/"
  cp ${../home/desktop/quickshell}/*.js "$out/"
  cp ${palette} "$out/Theme.qml"
  cat > "$out/qmldir" <<'EOF'
  singleton Theme 1.0 Theme.qml
  ActionButton 1.0 ActionButton.qml
  MusicCard 1.0 MusicCard.qml
  PowerMenu 1.0 PowerMenu.qml
  EOF
  export HOME="$TMPDIR/home" XDG_CACHE_HOME="$TMPDIR/cache" LANG=C.UTF-8
  mkdir -p "$HOME" "$XDG_CACHE_HOME"
  for file in "$out/"*.qml; do qmlformat --normalize "$file" > /dev/null; done
''
