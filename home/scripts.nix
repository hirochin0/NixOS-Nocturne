{ pkgs, ... }:
let
  script = name: runtimeInputs: text: pkgs.writeShellApplication { inherit name runtimeInputs text; };
in {
  home.packages = [
    (script "nocturne-launcher" [ pkgs.fuzzel ] ''
      exec fuzzel
    '')
    (script "nocturne-lock" [ pkgs.util-linux pkgs.hyprlock ] ''
      # flockでキーバインド・idle・sleepからの二重起動を防ぐ。
      exec flock --nonblock "''${XDG_RUNTIME_DIR:?}/nocturne-lock" hyprlock
    '')
    (script "nocturne-screenshot" [ pkgs.grim pkgs.slurp pkgs.wl-clipboard pkgs.libnotify pkgs.coreutils ] ''
      region=$(slurp) || exit 0
      mkdir -p "$HOME/Pictures/Screenshots"
      file=$(mktemp "$HOME/Pictures/Screenshots/shot-$(date +%Y%m%d-%H%M%S)-XXXXXX.png")
      if ! grim -g "$region" "$file"; then
        rm -f "$file"
        exit 1
      fi
      wl-copy --type image/png < "$file"
      notify-send "Screenshot saved" "$file"
    '')
    (script "nocturne-power" [ pkgs.fuzzel pkgs.systemd pkgs.uwsm ] ''
      choice=$(printf 'Lock\nSuspend\nLogout\nReboot\nShutdown\n' | fuzzel --dmenu --prompt 'Session ❯ ') || exit 0
      case "$choice" in
        Lock) nocturne-lock ;;
        Suspend) systemctl suspend ;;
        Logout|Reboot|Shutdown)
          confirm=$(printf 'Cancel\nConfirm\n' | fuzzel --dmenu --prompt "$choice ❯ ") || exit 0
          [ "$confirm" = "Confirm" ] || exit 0
          case "$choice" in
            Logout) uwsm stop ;;
            Reboot) systemctl reboot ;;
            Shutdown) systemctl poweroff ;;
          esac
          ;;
      esac
    '')
  ];
}
