{ config, pkgs, desktop, theme, ... }:
let
  target = config.wayland.systemd.target;
  tool = import ../../lib/wallpaper-tools.nix { inherit pkgs desktop theme; };
in {
  home.packages = [ desktop.swww tool ];
  home.file."Pictures/Wallpapers/Nocturne.png".source = theme.wallpaper;
  systemd.user.services.nocturne-wallpaper = {
    Unit = {
      Description = "NOCTURNE swww wallpaper";
      PartOf = [ target ];
      After = [ target ];
    };
    Service = {
      Type = "exec";
      ExecStart = "${desktop.swww}/bin/swww-daemon --no-cache";
      ExecStartPost = "${tool}/bin/nocturne-wallpaper restore";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStartSec = 40;
    };
    Install.WantedBy = [ target ];
  };
  xdg.desktopEntries.nocturne-wallpaper = {
    name = "Wallpaper";
    comment = "Choose a wallpaper for NOCTURNE";
    exec = "${tool}/bin/nocturne-wallpaper pick";
    icon = "preferences-desktop-wallpaper";
    terminal = false;
    categories = [ "Settings" ];
  };
}
