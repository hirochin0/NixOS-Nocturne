{ pkgs, desktop }:
pkgs.writeShellApplication {
  name = "nocturne-desktop";
  runtimeInputs = [ pkgs.python3 ];
  text = ''exec python3 ${../home/scripts/desktop_reveal.py} --hyprctl ${desktop.hyprland}/bin/hyprctl "$@"'';
}
