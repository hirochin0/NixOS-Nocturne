{ pkgs, desktop, theme }:
let
  tool = import ../lib/wallpaper-tools.nix { inherit pkgs desktop theme; };
  menuTheme = import ../lib/wallpaper-menu-theme.nix { inherit pkgs theme; };
in
pkgs.runCommand "nocturne-wallpaper-tests" {
  nativeBuildInputs = [ (pkgs.python3.withPackages (p: [ p.pillow ])) ];
  # Force the generated launcher through writeShellApplication / ShellCheck.
  toolPath = "${tool}/bin/nocturne-wallpaper";
} ''
  export HOME="$TMPDIR/home" XDG_CACHE_HOME="$TMPDIR/cache"
  mkdir -p "$HOME" "$XDG_CACHE_HOME"
  python3 ${./wallpaper_tools_test.py} ${../home/scripts/wallpaper.py}
  test -x "$toolPath"
  # rofi 2.0.0's -rasi-validate crashes during early cleanup, even for a
  # minimal valid theme. The normal theme-loading path can dump headlessly.
  ${desktop.rofi}/bin/rofi -no-config -theme ${menuTheme} -dump-theme > parsed.rasi 2> theme-errors
  test ! -s theme-errors
  grep -Eq 'columns: +3;' parsed.rasi
  grep -q 'element-icon' parsed.rasi
  ${desktop.swww}/bin/swww --version
  ${desktop.swww}/bin/swww-daemon --help | grep -q -- '--no-cache'
  ${desktop.swww}/bin/swww img --help | grep -q -- '--transition-duration'
  touch "$out"
''
