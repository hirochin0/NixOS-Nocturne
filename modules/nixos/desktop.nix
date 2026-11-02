{ config, lib, pkgs, user, ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  networking.hostName = lib.mkDefault user.hostName;
  networking.networkmanager.enable = lib.mkDefault true;
  programs.hyprland = { enable = true; withUWSM = true; };
  hardware.graphics.enable = true;
  security.polkit.enable = true;
  security.pam.services.hyprlock = {};
  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.upower.enable = true;
  services.blueman.enable = lib.mkDefault true;
  hardware.bluetooth.enable = lib.mkDefault true;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
  };
  security.rtkit.enable = true;
  programs.fish.enable = true;
  programs.dconf.enable = true;
  users.users.${user.name} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.fish;
  };
  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono noto-fonts-cjk-sans noto-fonts-color-emoji ];
  environment.systemPackages = with pkgs; [ git ];
  services.greetd = lib.mkIf user.enableGreetd {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
      user = "greeter";
    };
  };
  # Hyprland 0.55系のLua APIに合わせる。メジャー更新前にAPI差分を確認。
  assertions = [{
    assertion = lib.versionAtLeast config.programs.hyprland.package.version "0.55"
      && lib.versionOlder config.programs.hyprland.package.version "0.56";
    message = "NOCTURNE: Hyprland の想定範囲は 0.55系。Lua APIの変更点を確認してから対応範囲を更新してください。";
  }];
}
