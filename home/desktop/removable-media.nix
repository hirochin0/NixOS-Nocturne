{ config, lib, pkgs, ... }:
let
  target = config.wayland.systemd.target;
  tools = import ../../lib/removable-tools.nix { inherit pkgs; };
in {
  home.packages = [ tools ];
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
    settings = {
      program_options.file_manager = "${pkgs.thunar}/bin/thunar";
      device_config = [
        { is_external = true; id_type = "vfat"; options = [ "sync" ]; }
        { is_external = true; id_type = "exfat"; options = [ "sync" ]; }
      ];
    };
  };
  # Follow the real UWSM session, without depending on a tray target.
  systemd.user.services.udiskie = {
    Unit = {
      After = lib.mkForce [ target ];
      PartOf = lib.mkForce [ target ];
    };
    Service = { Restart = "on-failure"; RestartSec = 2; };
    Install.WantedBy = lib.mkForce [ target ];
  };
}
