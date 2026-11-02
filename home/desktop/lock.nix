{ pkgs, theme, ... }: {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = { hide_cursor = true; };
      background = [{ monitor = ""; path = "${theme.wallpaper}"; blur_passes = 3; blur_size = 7; }];
      label = [
        {
          monitor = "";
          text = "cmd[update:1000] date +'%H:%M'";
          color = "rgb(${theme.text})";
          font_size = 88;
          font_family = theme.font;
          position = "0, 130";
          halign = "center"; valign = "center";
        }
        {
          monitor = ""; text = "NOCTURNE / $USER";
          color = "rgb(${theme.muted})"; font_size = 14;
          font_family = theme.font; position = "0, 38";
          halign = "center"; valign = "center";
        }
      ];
      input-field = [{
        monitor = ""; size = "300, 56"; position = "0, -80";
        halign = "center"; valign = "center";
        inner_color = "rgb(${theme.surface})";
        outer_color = "rgb(${theme.accent})";
        font_color = "rgb(${theme.text})";
        check_color = "rgb(${theme.cyan})";
        fail_color = "rgb(${theme.red})";
        outline_thickness = 2; rounding = theme.radius;
        placeholder_text = "Password";
        fail_text = "Authentication failed";
      }];
    };
  };
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "nocturne-lock";
        before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
      };
      listener = [
        { timeout = 300; on-timeout = "${pkgs.systemd}/bin/loginctl lock-session"; }
        { timeout = 600; on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'"; on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'"; }
      ];
    };
  };
}
