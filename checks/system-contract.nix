{ nixpkgs, home-manager, user, theme, desktop, spicetify-nix }:
let
  lib = nixpkgs.lib;
  system = nixpkgs.lib.nixosSystem {
    system = user.system;
    specialArgs = { inherit user theme desktop; };
    modules = [
      ../modules/nixos/desktop.nix
      ../modules/nixos/japanese.nix
      home-manager.nixosModules.home-manager
      {
        # 評価専用のfixture。実機のディスク/ブート設定には使わない。
        system.stateVersion = "26.05";
        fileSystems."/" = { device = "/dev/disk/by-label/NOCTURNE-TEST-ONLY"; fsType = "ext4"; };
        boot.loader.systemd-boot.enable = true;
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit user theme desktop spicetify-nix; };
          users.${user.name} = import ../home;
        };
      }
    ];
  };
  cfg = system.config;
  hm = cfg.home-manager.users.${user.name};
  failures = lib.filter (a: !a.assertion) (cfg.assertions ++ hm.assertions);
in
assert lib.assertMsg (failures == []) (lib.concatMapStringsSep "\n" (a: a.message) failures);
assert cfg.programs.hyprland.withUWSM;
assert cfg.programs.hyprland.package.version == desktop.hyprland.version;
assert hm.wayland.systemd.target == "wayland-session@hyprland.desktop.target";
assert hm.dconf.enable;
assert hm.dconf.settings."org/gnome/desktop/interface".color-scheme == "prefer-dark";
assert hm.programs.waybar.package.version == desktop.waybar.version;
assert hm.programs.hyprlock.package.version == desktop.hyprlock.version;
assert hm.programs.kitty.package.outPath == desktop.kitty.outPath;
assert hm.programs.vscode.package.outPath == desktop.vscode.outPath;
assert !hm.programs.spicetify.enable;
assert lib.any (p: p.name == "nocturne-spotify") hm.home.packages;
assert lib.hasSuffix "/bin/spotify %U" hm.xdg.desktopEntries.spotify.exec;
assert !lib.elem desktop.spotify hm.home.packages;
assert hm.systemd.user.services.nocturne-wallpaper.Service.ExecStart == [ "${desktop.swww}/bin/swww-daemon --no-cache" ];
assert cfg.services.power-profiles-daemon.enable;
assert !cfg.services.tlp.enable && !cfg.services.auto-cpufreq.enable && !cfg.powerManagement.powertop.enable;
assert hm.programs.waybar.settings.main.battery.on-click == "nocturne-widgets power";
assert hm.systemd.user.services.nocturne-widgets.Unit.PartOf == [ hm.wayland.systemd.target ];
system.pkgs.writeText "nocturne-system-contract.json" (builtins.toJSON {
  hyprland = cfg.programs.hyprland.package.version;
  portal = cfg.programs.hyprland.portalPackage.version;
  mesa = cfg.hardware.graphics.package.version;
  kitty = hm.programs.kitty.package.version;
  applications = {
    vscode = hm.programs.vscode.package.version;
    chrome = desktop.google-chrome.version;
    codex = desktop.codex.version;
    neofetch = desktop.neofetch.version;
    swww = desktop.swww.version;
    quickshell = desktop.quickshell.version;
    spotify = desktop.spotify.version;
    spicetify = desktop.spicetify-cli.version;
  };
  inherit (hm.home) username;
  target = hm.wayland.systemd.target;
  dconfSettings = hm.dconf.settings;
  powerProfiles = cfg.services.power-profiles-daemon.enable;
  spotifyLauncher = hm.xdg.desktopEntries.spotify.exec;
  # forcing the HM activation script also checks module option generation.
  activation = builtins.unsafeDiscardStringContext hm.home.activationPackage.drvPath;
  services = builtins.attrNames hm.systemd.user.services;
})
