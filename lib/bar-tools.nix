{ pkgs, desktop }:
let tools = import ./tools.nix { inherit pkgs desktop; };
in pkgs.writeShellApplication {
  name = "nocturne-bar";
  runtimeInputs = [ pkgs.python3 pkgs.networkmanager pkgs.wireplumber pkgs.brightnessctl
    pkgs.networkmanagerapplet pkgs.pavucontrol tools.launcher tools.power ];
  text = ''exec python3 ${../home/scripts/bar.py} "$@"'';
}
