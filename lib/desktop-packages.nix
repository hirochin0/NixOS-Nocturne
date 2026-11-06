{ hyprland, swww, neofetch-src, system }:
let
  upstream = import hyprland.inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = pkg: builtins.elem (upstream.lib.getName pkg) [ "vscode" "google-chrome" "spotify" "discord" "discord-unwrapped" ];
  };
in {
  hyprland = hyprland.packages.${system}.hyprland;
  portal = hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  # EGL clients must use a libc compatible with the runtime-loaded Mesa driver.
  inherit (upstream) mesa kitty waybar hypridle hyprlock rofi quickshell cage;
  inherit (upstream.qt6) qtdeclarative;
  # GUI clients share Mesa's package set (including libc/libglvnd).
  inherit (upstream) vscode google-chrome codex spotify spicetify-cli discord;
  # ReGreet's authentication/controller stay upstream; only the login layout changes.
  regreet = upstream.regreet.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ../assets/regreet/lock-layout.patch ];
    # Keep Cargo's writable registry/cache inside the temporary build directory.
    preConfigure = (old.preConfigure or "") + ''
      export CARGO_HOME="$TMPDIR/cargo-home"
    '';
  });
  swww = swww.packages.${system}.swww;
  neofetch = upstream.callPackage ./neofetch.nix { src = neofetch-src; };
  mesa32 = upstream.pkgsi686Linux.mesa;
}
