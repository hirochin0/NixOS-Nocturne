{ pkgs, desktop, theme }:
pkgs.writeShellApplication {
  name = "nocturne-wallpaper";
  runtimeInputs = [ pkgs.python3 ];
  text = ''
    exec python3 ${../home/scripts/wallpaper.py} \
      --swww ${desktop.swww}/bin/swww \
      --fuzzel ${pkgs.fuzzel}/bin/fuzzel \
      --default ${theme.wallpaper} \
      --directory "$HOME/Pictures/Wallpapers" "$@"
  '';
}
