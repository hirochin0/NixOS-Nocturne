{ pkgs, desktop, theme, spicetify-nix, ... }:
let
  # Keep inputs pinned, but patch a user-owned copy at launch, not /nix/store.
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  colors = pkgs.writeText "nocturne-spicetify-colors.ini" (pkgs.lib.generators.toINI {} {
    Nocturne = {
      text = theme.text; subtext = theme.muted; main = theme.bg;
      sidebar = theme.bg; player = theme.surface; card = theme.elevated;
      shadow = "000000"; selected-row = theme.text; button = theme.cyan;
      button-active = theme.accent; button-disabled = theme.muted;
      tab-active = theme.elevated; notification = theme.surface;
      notification-error = theme.red; misc = theme.accent;
    };
  });
  settings = pkgs.writeText "nocturne-spotify-runtime.json" (builtins.toJSON {
    spotify = "${desktop.spotify}";
    cli = "${desktop.spicetify-cli}/bin/spicetify";
    marketplace = "${spicePkgs.apps.marketplace.src}";
    theme = "${./spicetify/Nocturne}";
    inherit colors;
    notify = "${pkgs.libnotify}/bin/notify-send";
  });
  launcher = pkgs.writeShellScriptBin "spotify" ''
    exec ${pkgs.python3}/bin/python3 ${../scripts/spotify-runtime.py} ${settings} launch "$@"
  '';
  cli = pkgs.writeShellScriptBin "spicetify" ''
    exec ${pkgs.python3}/bin/python3 ${../scripts/spotify-runtime.py} ${settings} cli "$@"
  '';
  package = pkgs.symlinkJoin {
    name = "nocturne-spotify";
    paths = [ launcher cli ];
    postBuild = ''
      mkdir -p "$out/share"
      ln -s ${desktop.spotify}/share/icons "$out/share/icons"
    '';
  };
in {
  imports = [ spicetify-nix.homeManagerModules.spicetify ];
  programs.spicetify.enable = false;
  home.packages = [ package ];
  xdg.desktopEntries.spotify = {
    name = "Spotify";
    genericName = "Music Player";
    exec = "${package}/bin/spotify %U";
    icon = "spotify-client";
    terminal = false;
    categories = [ "Audio" "Music" "Player" "AudioVideo" ];
    mimeType = [ "x-scheme-handler/spotify" ];
  };
}
