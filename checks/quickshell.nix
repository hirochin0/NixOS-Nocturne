{ pkgs, desktop, theme, user }:
let
  bundle = import ../lib/quickshell-config.nix { inherit pkgs desktop theme user; };
in pkgs.runCommand "nocturne-quickshell-check" {
  nativeBuildInputs = [ desktop.qtdeclarative desktop.quickshell pkgs.nodejs ];
} ''
  export HOME="$TMPDIR/home" XDG_CACHE_HOME="$TMPDIR/cache" LANG=C.UTF-8
  mkdir -p "$HOME" "$XDG_CACHE_HOME" "$out"
  for file in ${bundle}/*.qml; do
    qmlformat --normalize "$file" > /dev/null
  done
  node ${./quickshell-logic.cjs} ${bundle}/Logic.js > "$out/logic.log"
  export XDG_RUNTIME_DIR="$TMPDIR/runtime"
  export QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_QUICK_CONTROLS_STYLE=Basic
  mkdir -m 700 "$XDG_RUNTIME_DIR"
  substitute ${./quickshell-card.qml} "$TMPDIR/card-check.qml" --subst-var-by bundle ${bundle}
  if ! timeout 10s quickshell --path "$TMPDIR/card-check.qml" --no-color > "$out/card.log" 2>&1; then
    cat "$out/card.log"
    exit 1
  fi
  grep -q NOCTURNE_CARD_CHECK_PASSED "$out/card.log"
  if grep -Eq 'ReferenceError|TypeError|Unable to assign|Failed to load configuration' "$out/card.log"; then
    cat "$out/card.log"
    exit 1
  fi
  cp -r ${bundle} "$out/config"
''
