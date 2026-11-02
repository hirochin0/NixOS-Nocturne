{ pkgs, theme, ... }: {
  gtk = {
    enable = true;
    theme = { name = "adw-gtk3-dark"; package = pkgs.adw-gtk3; };
    iconTheme = { name = "Papirus-Dark"; package = pkgs.papirus-icon-theme; };
    font = { name = "Noto Sans CJK JP"; size = 10; };
  };
  home.pointerCursor = {
    name = "Bibata-Modern-Ice"; package = pkgs.bibata-cursors;
    size = 24; gtk.enable = true; x11.enable = true;
  };
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  xdg.configFile."wallpapers/nocturne.png".source = theme.wallpaper;
}
