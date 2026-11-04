{ hyprland, swww, neofetch-src, system }:
let
  upstream = import hyprland.inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = pkg: builtins.elem (upstream.lib.getName pkg) [ "vscode" "google-chrome" ];
  };
in {
  hyprland = hyprland.packages.${system}.hyprland;
  portal = hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  # EGL clients must use a libc compatible with the runtime-loaded Mesa driver.
  inherit (upstream) mesa kitty waybar hypridle hyprlock rofi;
  # GUI clients share Mesa's package set (including libc/libglvnd).
  inherit (upstream) vscode google-chrome codex;
  swww = swww.packages.${system}.swww;
  neofetch = upstream.callPackage ./neofetch.nix { src = neofetch-src; };
  mesa32 = upstream.pkgsi686Linux.mesa;
}
