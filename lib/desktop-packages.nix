{ hyprland, system }:
let upstream = hyprland.inputs.nixpkgs.legacyPackages.${system};
in {
  hyprland = hyprland.packages.${system}.hyprland;
  portal = hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  # EGL clients must use a libc compatible with the runtime-loaded Mesa driver.
  inherit (upstream) mesa kitty waybar hypridle hyprlock;
  mesa32 = upstream.pkgsi686Linux.mesa;
}
