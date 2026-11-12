{ pkgs, desktop, theme, user }:
let
  bundle = import ../lib/quickshell-config.nix { inherit pkgs desktop theme user; };
in pkgs.runCommand "nocturne-quickshell-check" {
  nativeBuildInputs = [ desktop.qtdeclarative desktop.quickshell pkgs.nodejs pkgs.python3 ];
} ''
  export HOME="$TMPDIR/home" XDG_CACHE_HOME="$TMPDIR/cache" LANG=C.UTF-8
  mkdir -p "$HOME" "$XDG_CACHE_HOME" "$out"
  for file in ${bundle}/*.qml; do
    qmlformat --normalize "$file" > /dev/null
  done
  python ${./icon_catalog_test.py} ${../home/scripts/icon_catalog.py} > "$out/icon-catalog.log" 2>&1
  python ${./bar_tools_test.py} ${../home/scripts/bar.py} > "$out/bar-tools.log" 2>&1
  python ${./launcher_migrate_test.py} ${../home/scripts/launcher_migrate.py} ${../home/desktop/quickshell/launcher-defaults.json} > "$out/launcher-migration.log" 2>&1
  python ${./lyrics_test.py} ${../home/scripts/lyrics.py} > "$out/lyrics-fetch.log" 2>&1
  node ${./lyrics-logic.cjs} ${bundle}/LyricsLogic.js > "$out/lyrics-logic.log"
  node ${./branch-logic.cjs} ${bundle}/BranchLogic.js ${bundle}/launcher-defaults.json > "$out/branches.log"
  node ${./dino-logic.cjs} ${bundle}/DinoLogic.js > "$out/dino-logic.log"
  node ${./clock-logic.cjs} ${bundle}/ClockLogic.js > "$out/clock-logic.log"
  node ${./focus-logic.cjs} ${bundle}/FocusLogic.js ${bundle}/BarContent.qml > "$out/focus.log"
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
  python ${./battery_tools_test.py} ${../home/scripts/battery.py} > "$out/battery.log" 2>&1
  substitute ${./power-card.qml} "$TMPDIR/power-check.qml" --subst-var-by bundle ${bundle}
  if ! timeout 10s quickshell --path "$TMPDIR/power-check.qml" --no-color > "$out/power.log" 2>&1; then
    cat "$out/power.log"
    exit 1
  fi
  grep -q NOCTURNE_POWER_CARD_CHECK_PASSED "$out/power.log"
  if grep -Eq 'ReferenceError|TypeError|Unable to assign|Failed to load configuration' "$out/power.log"; then
    cat "$out/power.log"
    exit 1
  fi
  substitute ${./arc-launcher.qml} "$TMPDIR/arc-check.qml" --subst-var-by bundle ${bundle}
  if ! timeout 10s quickshell --path "$TMPDIR/arc-check.qml" --no-color > "$out/arc.log" 2>&1; then
    cat "$out/arc.log"
    exit 1
  fi
  grep -q NOCTURNE_ARC_CHECK_PASSED "$out/arc.log"
  if grep -Eq 'ReferenceError|TypeError|Unable to assign|Failed to load configuration' "$out/arc.log"; then
    cat "$out/arc.log"
    exit 1
  fi
  substitute ${./taskbar.qml} "$TMPDIR/taskbar-check.qml" --subst-var-by bundle ${bundle}
  if ! timeout 10s quickshell --path "$TMPDIR/taskbar-check.qml" --no-color > "$out/taskbar.log" 2>&1; then
    cat "$out/taskbar.log"
    exit 1
  fi
  grep -q NOCTURNE_TASKBAR_CHECK_PASSED "$out/taskbar.log"
  if grep -Eq 'ReferenceError|TypeError|Unable to assign|Failed to load configuration' "$out/taskbar.log"; then
    cat "$out/taskbar.log"
    exit 1
  fi
  substitute ${./glass-clock.qml} "$TMPDIR/clock-check.qml" --subst-var-by bundle ${bundle}
  if ! timeout 10s quickshell --path "$TMPDIR/clock-check.qml" --no-color > "$out/clock.log" 2>&1; then
    cat "$out/clock.log"
    exit 1
  fi
  grep -q NOCTURNE_CLOCK_CHECK_PASSED "$out/clock.log"
  if grep -Eq 'ReferenceError|TypeError|Unable to assign|Failed to load configuration' "$out/clock.log"; then
    cat "$out/clock.log"
    exit 1
  fi
  substitute ${./dino-game.qml} "$TMPDIR/dino-check.qml" --subst-var-by bundle ${bundle}
  if ! timeout 10s quickshell --path "$TMPDIR/dino-check.qml" --no-color > "$out/dino.log" 2>&1; then
    cat "$out/dino.log"
    exit 1
  fi
  grep -q NOCTURNE_DINO_CHECK_PASSED "$out/dino.log"
  if grep -Eq 'ReferenceError|TypeError|Unable to assign|Failed to load configuration|Failed to initialize QSettings' "$out/dino.log"; then
    cat "$out/dino.log"
    exit 1
  fi
  cp -r ${bundle} "$out/config"
''
