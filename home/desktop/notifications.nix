{ config, pkgs, theme, ... }: {
  systemd.user.services.mako = {
    Unit = {
      Description = "NOCTURNE notifications";
      PartOf = [ config.wayland.systemd.target ];
      After = [ config.wayland.systemd.target ];
    };
    Service = { ExecStart = "${pkgs.mako}/bin/mako"; Restart = "on-failure"; };
    Install.WantedBy = [ config.wayland.systemd.target ];
  };
  services.mako = {
    enable = true;
    settings = {
      font = "${theme.font} 11";
      background-color = "#${theme.bg}f5";
      text-color = "#${theme.text}";
      border-color = "#${theme.accent}";
      border-size = 2;
      border-radius = theme.radius;
      padding = "16";
      margin = "14";
      width = 340;
      default-timeout = 5000;
      anchor = "top-right";
      "urgency=critical" = { border-color = "#${theme.red}"; default-timeout = 0; };
    };
  };
}
