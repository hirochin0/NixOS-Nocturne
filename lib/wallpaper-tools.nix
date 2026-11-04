{ pkgs, desktop, theme }:
let
  python = pkgs.python3.withPackages (p: [ p.pillow ]);
  menuTheme = import ./wallpaper-menu-theme.nix { inherit pkgs theme; };
in
pkgs.writeShellApplication {
  name = "nocturne-wallpaper";
  runtimeInputs = [ python ];
  text = ''
    exec python3 ${../home/scripts/wallpaper.py} \
      --swww ${desktop.swww}/bin/swww \
      --rofi ${desktop.rofi}/bin/rofi \
      --menu-theme ${menuTheme} \
      --default ${theme.wallpaper} \
      --directory "$HOME/Pictures/Wallpapers" "$@"
  '';
}
