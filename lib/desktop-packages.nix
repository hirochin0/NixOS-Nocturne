{ hyprland, system }:
let upstream = hyprland.inputs.nixpkgs.legacyPackages.${system};
in {
  hyprland = hyprland.packages.${system}.hyprland;
  portal = hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  inherit (upstream) mesa waybar hypridle hyprlock;
  mesa32 = upstream.pkgsi686Linux.mesa;
}
