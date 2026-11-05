{ desktop, theme, spicetify-nix, ... }: {
  imports = [ spicetify-nix.homeManagerModules.spicetify ];

  # The module installs the modified Spotify. Do not also add desktop.spotify
  # to home.packages: that would expose two competing spotify launchers.
  programs.spicetify = {
    enable = true;
    spotifyPackage = desktop.spotify;
    spicetifyPackage = desktop.spicetify-cli;
    wayland = true;
    theme = {
      name = "Nocturne";
      src = ./spicetify/Nocturne;
      injectThemeJs = false;
    };
    customColorScheme = {
      text = theme.text;
      subtext = theme.muted;
      main = theme.bg;
      sidebar = theme.bg;
      player = theme.surface;
      card = theme.elevated;
      shadow = "000000";
      "selected-row" = theme.text;
      button = theme.cyan;
      "button-active" = theme.accent;
      "button-disabled" = theme.muted;
      "tab-active" = theme.elevated;
      notification = theme.surface;
      "notification-error" = theme.red;
      misc = theme.accent;
    };
    # Add pinned extensions/custom apps here, then rebuild.
    enabledExtensions = [];
    enabledCustomApps = [];
  };
  home.packages = [ desktop.spicetify-cli ];
}
