{ config, lib, pkgs, user, desktop, ... }: {
  imports = [ ./power.nix ./login.nix ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.extra-substituters = [ "https://hyprland.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  networking.hostName = lib.mkDefault user.hostName;
  networking.networkmanager.enable = lib.mkDefault true;
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = desktop.hyprland;
    portalPackage = desktop.portal;
  };
  hardware.graphics = {
    enable = true;
    package = desktop.mesa;
    # 既存環境でenable32Bitが有効なら同じMesa集合に揃える。
    package32 = lib.mkIf config.hardware.graphics.enable32Bit desktop.mesa32;
  };
  security.polkit.enable = true;
  # brightnessctl ships the udev rules granting backlight access to video.
  services.udev.packages = [ pkgs.brightnessctl ];
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
  assertions = [{
    assertion = lib.versionAtLeast config.programs.hyprland.package.version "0.57.1"
      && lib.versionOlder config.programs.hyprland.package.version "0.58";
    message = "NOCTURNE: Hyprland v0.57.1系のLua APIを使用します。パッケージと設定を一緒に更新してください。";
  }];
}
