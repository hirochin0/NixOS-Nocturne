{ theme, desktop, ... }: {
  programs.kitty = {
    enable = true;
    package = desktop.kitty;
    font = { name = theme.font; size = theme.fontSize; };
    keybindings = {
      # Arrow keys avoid ambiguity around shifted +/= keys on Japanese layouts.
      "ctrl+alt+up" = "change_font_size all +2.0";
      "ctrl+alt+down" = "change_font_size all -2.0";
      "ctrl+alt+backspace" = "change_font_size all 0";
    };
    settings = {
      background = "#${theme.bg}";
      foreground = "#${theme.text}";
      selection_background = "#${theme.accent}";
      selection_foreground = "#${theme.bg}";
      cursor = "#${theme.cyan}";
      background_opacity = "0.92";
      window_padding_width = 18;
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      tab_bar_style = "powerline";
      active_tab_background = "#${theme.accent}";
      active_tab_foreground = "#${theme.bg}";
      color0 = "#${theme.surface}"; color8 = "#${theme.muted}";
      color1 = "#${theme.red}"; color9 = "#${theme.red}";
      color2 = "#${theme.green}"; color10 = "#${theme.green}";
      color3 = "#${theme.yellow}"; color11 = "#${theme.yellow}";
      color4 = "#${theme.accent}"; color12 = "#${theme.accent}";
      color5 = "#cba6f7"; color13 = "#cba6f7";
      color6 = "#${theme.cyan}"; color14 = "#${theme.cyan}";
      color7 = "#${theme.text}"; color15 = "#ffffff";
    };
  };
}
