{ pkgs, desktop, user, theme }:
let
  tools = import ./tools.nix { inherit pkgs desktop; };
  wallpaper = import ./wallpaper-tools.nix { inherit pkgs desktop theme; };
  command = package: executable: "${package}/bin/${executable}";
  generated = pkgs.writeText "nocturne-generated.lua" (
    "return " + pkgs.lib.generators.toLua {} {
      inherit (user) monitors keyboardLayout;
      inherit theme;
      commands = {
        terminal = command desktop.kitty "kitty";
        browser = command desktop.google-chrome "google-chrome-stable";
        files = command pkgs.thunar "thunar";
        launcher = pkgs.lib.getExe tools.launcher;
        wallpaper = "${wallpaper}/bin/nocturne-wallpaper pick";
        lock = pkgs.lib.getExe tools.lock;
        power = pkgs.lib.getExe tools.power;
        screenshot = pkgs.lib.getExe tools.screenshot;
        volume = command pkgs.wireplumber "wpctl";
        brightness = command pkgs.brightnessctl "brightnessctl";
        media = command pkgs.playerctl "playerctl";
      };
    }
  );
in pkgs.runCommand "nocturne-hyprland-config" {
  nativeBuildInputs = [ desktop.hyprland pkgs.lua ];
} ''
  mkdir -p "$out" "$TMPDIR/home" "$TMPDIR/runtime" "$TMPDIR/config/hypr"
  cp ${../home/desktop/hypr}/*.lua "$out/"
  cp ${generated} "$out/generated.lua"
  for file in "$out/"*.lua; do luac -p "$file"; done
  cp "$out/"*.lua "$TMPDIR/config/hypr/"
  export HOME="$TMPDIR/home"
  export XDG_CONFIG_HOME="$TMPDIR/config"
  export XDG_RUNTIME_DIR="$TMPDIR/runtime"
  chmod 700 "$XDG_RUNTIME_DIR"
  flags=()
  if [ "$(id -u)" = 0 ]; then flags+=(--i-am-really-stupid); fi
  # GPUを起動せず、実際のHyprlandのLua APIと設定キーを検証する。
  Hyprland "''${flags[@]}" --verify-config --config "$out/hyprland.lua" > "$out/validation.log" 2>&1 || {
    cat "$out/validation.log"
    exit 1
  }
''
