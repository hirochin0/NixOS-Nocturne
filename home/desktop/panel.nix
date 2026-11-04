{ lib, config, pkgs, theme, desktop, ... }:
let
  brightness = import ../../lib/brightness.nix { inherit pkgs; };
in {
  # HMはtray.targetもWantedByに追加するため、他DEでの二重起動を防ぐ。
  systemd.user.services.waybar.Install.WantedBy = lib.mkForce [ config.wayland.systemd.target ];
  programs.waybar = {
    enable = true;
    package = desktop.waybar;
    systemd.enable = true;
    settings.main = {
      layer = "top";
      position = "top";
      height = 38;
      margin-top = 10;
      margin-left = 14;
      margin-right = 14;
      spacing = 6;
      modules-left = [ "custom/launcher" "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "network" "pulseaudio" "backlight" "battery" "tray" "custom/power" ];
      "custom/launcher" = { format = "󱄅"; tooltip-format = "Applications"; on-click = "nocturne-launcher"; };
      "hyprland/workspaces" = {
        format = "{name}";
        on-click = "activate";
        persistent-workspaces."*" = [ 1 2 3 4 5 ];
      };
      clock = { format = "{:%a  %m.%d   ·   %H:%M}"; tooltip-format = "<tt>{calendar}</tt>"; };
      network = {
        format-wifi = "󰖩  {signalStrength}%";
        format-ethernet = "󰈀  LAN";
        format-disconnected = "󰖪  Offline";
        tooltip-format = "{ifname}: {ipaddr}";
        on-click = "nm-connection-editor";
      };
      pulseaudio = {
        format = "󰕾  {volume}%";
        format-muted = "󰖁  Mute";
        on-click = "pavucontrol";
        on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        scroll-step = 5;
      };
      backlight = {
        format = "󰃠  {percent}%";
        tooltip-format = "画面の明るさ: {percent}%\nスクロール: 5%ずつ調整\nSuper+F5 / F6: 暗く / 明るく";
        interval = 1;
        on-scroll-up = brightness.up;
        on-scroll-down = brightness.down;
      };
      battery = {
        format = "{icon}  {capacity}%";
        format-charging = "󰂄  {capacity}%";
        format-icons = [ "󰁺" "󰁼" "󰁾" "󰂀" "󰁹" ];
        states = { warning = 25; critical = 12; };
      };
      tray.spacing = 10;
      "custom/power" = { format = "󰐥"; tooltip-format = "Session"; on-click = "nocturne-power"; };
    };
    style = ''
      * { font-family: "${theme.font}", "Noto Sans CJK JP"; font-size: 12px; border: none; min-height: 0; }
      window#waybar { background: transparent; color: #${theme.text}; }
      .modules-left, .modules-center, .modules-right {
        background: alpha(#${theme.bg}, 0.94); border: 1px solid #${theme.elevated};
        border-radius: ${toString theme.radius}px; padding: 3px 9px;
      }
      #custom-launcher { color: #${theme.accent}; font-size: 22px; padding: 0 12px 0 4px; }
      #workspaces button { color: #${theme.muted}; padding: 0 10px; border-radius: 9px; margin: 2px; }
      #workspaces button.active { color: #${theme.bg}; background: #${theme.accent}; }
      #workspaces button:hover { background: #${theme.elevated}; color: #${theme.text}; }
      #workspaces button.urgent, #battery.critical { color: #${theme.red}; }
      #clock { padding: 0 16px; color: #${theme.text}; }
      #network, #pulseaudio, #backlight, #battery, #tray { padding: 0 9px; }
      #network { color: #${theme.cyan}; }
      #backlight { color: #${theme.yellow}; }
      #battery.charging { color: #${theme.green}; }
      #battery.warning { color: #${theme.yellow}; }
      #custom-power { color: #${theme.accent}; padding: 0 8px; }
      tooltip { background: #${theme.surface}; border: 1px solid #${theme.elevated}; border-radius: 10px; }
    '';
  };
}
