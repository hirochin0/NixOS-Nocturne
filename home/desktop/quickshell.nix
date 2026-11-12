{ config, pkgs, lib, desktop, theme, user, ... }:
let
  bundle = import ../../lib/quickshell-config.nix { inherit pkgs desktop theme user; };
  target = config.wayland.systemd.target;
in {
  home.packages = [ desktop.quickshell ];
  # Seed writable settings, then apply versioned migrations once.
  home.activation.nocturneLauncher = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    configDir=${lib.escapeShellArg "${config.xdg.configHome}/nocturne"}
    $DRY_RUN_CMD mkdir -p "$configDir"
    if [ ! -e "$configDir/launcher.json" ]; then
      $DRY_RUN_CMD cp ${./quickshell/launcher-defaults.json} "$configDir/launcher.json"
      $DRY_RUN_CMD chmod u+w "$configDir/launcher.json"
    else
      $DRY_RUN_CMD ${pkgs.python3}/bin/python ${../scripts/launcher_migrate.py} "$configDir/launcher.json" ${./quickshell/launcher-defaults.json}
    fi
  '';

  xdg.configFile."quickshell/nocturne".source = bundle;
  systemd.user.services.nocturne-widgets = {
    Unit = {
      Description = "NOCTURNE Quickshell taskbar and desktop widgets";
      PartOf = [ target ];
      After = [ target ];
    };
    Service = {
      ExecStart = "${desktop.quickshell}/bin/quickshell --path ${lib.escapeShellArg "${config.xdg.configHome}/quickshell/nocturne"} --no-duplicate";
      Restart = "on-failure";
      RestartSec = 3;
      Environment = [ "QT_QPA_PLATFORM=wayland" "QS_ICON_THEME=Papirus-Dark" ];
    };
    Install.WantedBy = [ target ];
  };
  assertions = [{
    assertion = lib.versionAtLeast desktop.quickshell.version "0.3.2";
    message = "NOCTURNE widgets require Quickshell 0.3.2 or newer.";
  }];
}
