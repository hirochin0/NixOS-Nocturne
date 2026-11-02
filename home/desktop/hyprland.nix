{ lib, pkgs, user, theme, ... }:
let
  q = builtins.toJSON;
in {
  xdg.configFile."hypr/hyprland.lua".text = ''
    local dir = os.getenv("HOME") .. "/.config/hypr/"
    ${lib.concatMapStringsSep "\n" (m: ''
      hl.monitor({ output = ${q m.output}, mode = ${q m.mode}, position = ${q m.position}, scale = ${toString m.scale} })
    '') user.monitors}
    dofile(dir .. "appearance.lua")
    dofile(dir .. "input.lua")
    dofile(dir .. "binds.lua")
    hl.on("hyprland.start", function()
      hl.exec_cmd("${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1")
    end)
  '';
  xdg.configFile."hypr/appearance.lua".text = ''
    hl.config({
      general = {
        gaps_in = 6, gaps_out = 14, border_size = 2,
        ["col.active_border"] = "rgb(${theme.accent}) rgb(${theme.cyan}) 45deg",
        ["col.inactive_border"] = "rgb(${theme.elevated})",
        layout = "dwindle", resize_on_border = true,
      },
      decoration = {
        rounding = ${toString theme.radius},
        active_opacity = 1.0, inactive_opacity = 0.97,
        blur = { enabled = true, size = 5, passes = 2, vibrancy = 0.15 },
        shadow = { enabled = true, range = 20, render_power = 3, color = "rgba(00000055)" },
      },
      animations = { enabled = true },
      dwindle = { pseudotile = true, preserve_split = true },
      misc = { disable_hyprland_logo = true, disable_splash_rendering = true, vrr = 0 },
    })
  '';
  xdg.configFile."hypr/input.lua".text = ''
    hl.config({ input = {
      kb_layout = ${q user.keyboardLayout}, follow_mouse = 1, sensitivity = 0,
      touchpad = { natural_scroll = true, ["tap-to-click"] = true, disable_while_typing = true },
    } })
  '';
  xdg.configFile."hypr/binds.lua".source = ./hypr/binds.lua;
  # 壁紙は安定したswaybgのCLIで表示。UWSMのセッション終了に追従。
  systemd.user.services.nocturne-wallpaper = {
    Unit = {
      Description = "NOCTURNE wallpaper";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${theme.wallpaper} -m fill";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
