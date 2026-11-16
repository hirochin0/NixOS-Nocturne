{ pkgs, desktop }:
pkgs.writeShellApplication {
  name = "nocturne-displays";
  runtimeInputs = [ pkgs.python3 ];
  text = ''exec python3 ${../home/scripts/displays.py} --hyprctl ${desktop.hyprland}/bin/hyprctl "$@"'';
}
