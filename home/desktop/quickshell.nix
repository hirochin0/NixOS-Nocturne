{ config, pkgs, lib, desktop, theme, user, ... }:
let
  bundle = import ../../lib/quickshell-config.nix { inherit pkgs desktop theme user; };
  target = config.wayland.systemd.target;
in {
  home.packages = [ desktop.quickshell desktop.spotify ];
  xdg.configFile."quickshell/nocturne".source = bundle;
  systemd.user.services.nocturne-widgets = {
    Unit = {
      Description = "NOCTURNE Quickshell music and power widgets";
      PartOf = [ target ];
      After = [ target ];
    };
    Service = {
      ExecStart = "${desktop.quickshell}/bin/quickshell --path ${lib.escapeShellArg "${config.xdg.configHome}/quickshell/nocturne"} --no-duplicate";
      Restart = "on-failure";
      RestartSec = 3;
      Environment = [ "QT_QPA_PLATFORM=wayland" ];
    };
    Install.WantedBy = [ target ];
  };
  assertions = [{
    assertion = lib.versionAtLeast desktop.quickshell.version "0.3.2";
    message = "NOCTURNE widgets require Quickshell 0.3.2 or newer.";
  }];
}
