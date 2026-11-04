{ config, pkgs, user, ... }: {
  imports = [
    ./desktop/hyprland.nix
    ./desktop/panel.nix
    ./desktop/launcher.nix
    ./desktop/notifications.nix
    ./desktop/lock.nix
    ./desktop/theme.nix
    ./desktop/dconf.nix
    ./programs/terminal.nix
    ./programs/shell.nix
    ./scripts.nix
  ];
  home = {
    username = user.name;
    homeDirectory = "/home/${user.name}";
    stateVersion = user.homeStateVersion;
    packages = with pkgs; [
      firefox thunar pavucontrol networkmanagerapplet blueman
      wl-clipboard grim slurp swappy playerctl brightnessctl
      libnotify jq ripgrep fd unzip nano
    ];
    sessionVariables = { NIXOS_OZONE_WL = "1"; EDITOR = "nano"; };
  };
  xdg.enable = true;
  programs.home-manager.enable = true;
  xdg.configFile."uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
}
