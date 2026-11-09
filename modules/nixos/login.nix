{ config, lib, pkgs, desktop, user, theme, ... }:
let
  cfg = config.programs.regreet;
  # Keep the existing UWSM desktop ID: the bar/widgets depend on this target.
  session = pkgs.writeTextFile {
    name = "nocturne-login-session";
    destination = "/share/wayland-sessions/nocturne.desktop";
    text = ''
      [Desktop Entry]
      Name=NOCTURNE (Hyprland)
      Comment=Hyprland desktop managed by UWSM
      Exec=${lib.getExe config.programs.uwsm.package} start -e -D Hyprland hyprland.desktop
      Type=Application
      DesktopNames=Hyprland
    '';
    derivationArgs.passthru.providedSessions = [ "nocturne" ];
  };
  greeter = pkgs.writeShellScript "nocturne-greeter" ''
    export XKB_DEFAULT_LAYOUT=${lib.escapeShellArg user.keyboardLayout}
    export LANG=C.UTF-8 LC_ALL=C.UTF-8 LANGUAGE=en
    export GDK_BACKEND=wayland
    export GTK_USE_PORTAL=0
    # Only offer the UWSM session, rather than the unmanaged Hyprland entry.
    export XDG_DATA_DIRS=${lib.escapeShellArg "${session}/share:${cfg.iconTheme.package}/share:${cfg.theme.package}/share"}
    exec ${pkgs.dbus}/bin/dbus-run-session \
      ${lib.getExe desktop.cage} ${lib.escapeShellArgs cfg.cageArgs} -- ${lib.getExe cfg.package}
  '';
in {
  config = lib.mkIf user.enableGreetd {
    # A single login manager must own tty1. Base hardware/boot files stay intact.
    services.displayManager.sddm.enable = lib.mkForce false;
    services.displayManager.gdm.enable = lib.mkForce false;
    services.displayManager.ly.enable = lib.mkForce false;
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;
    services.displayManager.autoLogin.enable = lib.mkForce false;
    services.displayManager.sessionPackages = [ session ];

    programs.regreet = {
      enable = true;
      package = desktop.regreet;
      # Show on one connected output and keep Ctrl+Alt+Fn available.
      cageArgs = [ "-s" "-m" "last" ];
      font = {
        package = pkgs.noto-fonts-cjk-sans;
        name = "Noto Sans CJK JP";
        size = 12;
      };
      theme.name = "Adwaita-dark";
      extraCss = import ../../lib/login-style.nix { inherit pkgs theme; };
      settings = {
        skip_selection = true;
        # Restore the desktop locale after greetd's English-only authentication UI.
        env = { LANG = config.i18n.defaultLocale; LC_ALL = ""; LANGUAGE = ""; };
        GTK.application_prefer_dark_theme = true;
        appearance.greeting_msg = "NOCTURNE";
        widget.clock = {
          format = "%H:%M";
          resolution = "30s";
          timezone = "Asia/Tokyo";
          label_width = 400;
        };
        commands = {
          reboot = [ "${pkgs.systemd}/bin/systemctl" "reboot" ];
          poweroff = [ "${pkgs.systemd}/bin/systemctl" "poweroff" ];
        };
      };
    };
    systemd.services.greetd.environment = {
      LANG = "C.UTF-8";
      LC_ALL = "C.UTF-8";
      LANGUAGE = "en";
    };
    services.greetd = {
      enable = true;
      useTextGreeter = false;
      # Replace any old initial_session/autologin too: show the GUI on every boot.
      settings = lib.mkForce {
        terminal.vt = 1;
        default_session = { command = "${greeter}"; user = "greeter"; };
      };
    };
  };
}
