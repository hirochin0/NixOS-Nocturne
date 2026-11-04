{ pkgs, desktop, theme }:
let tool = import ../lib/wallpaper-tools.nix { inherit pkgs desktop theme; };
in pkgs.runCommand "nocturne-wallpaper-tests" {
  nativeBuildInputs = [ pkgs.python3 ];
  # Force the generated launcher through writeShellApplication / ShellCheck.
  toolPath = "${tool}/bin/nocturne-wallpaper";
} ''
  python3 ${./wallpaper_tools_test.py} ${../home/scripts/wallpaper.py}
  test -x "$toolPath"
  ${desktop.swww}/bin/swww --version
  ${desktop.swww}/bin/swww-daemon --help | grep -q -- '--no-cache'
  ${desktop.swww}/bin/swww img --help | grep -q -- '--transition-duration'
  touch "$out"
''
