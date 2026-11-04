{ lib, pkgs, desktop, user, theme, ... }:
let
  bundle = import ../../lib/hyprland-config.nix { inherit pkgs desktop user theme; };
  target = "wayland-session@hyprland.desktop.target";
in {
  # UWSMにセッションを任せ、HM独自のHyprland systemd統合は使わない。
  wayland.systemd.target = target;
  xdg.configFile = lib.genAttrs (map (name: "hypr/${name}") [
    "hyprland.lua" "generated.lua" "binds.lua" "appearance.lua" "input.lua"
  ]) (name: { source = "${bundle}/${baseNameOf name}"; });
  systemd.user.services.nocturne-polkit = {
    Unit = { Description = "NOCTURNE polkit agent"; PartOf = [ target ]; After = [ target ]; };
    Service = {
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };
    Install.WantedBy = [ target ];
  };
}
