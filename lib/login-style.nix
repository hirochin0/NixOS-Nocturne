{ pkgs, theme }:
pkgs.writeText "nocturne-login.css" ''
  /* GTK4 CSS. Load the static wallpaper here, without a video decoding process. */
  @define-color accent_color #${theme.cyan};
  @define-color accent_bg_color #${theme.accent};
  @define-color accent_fg_color #${theme.bg};
  @define-color window_bg_color #${theme.bg};
  @define-color window_fg_color #${theme.text};

  window {
    color: #${theme.text};
    background-color: #${theme.bg};
    background-image: linear-gradient(135deg, alpha(#${theme.bg}, 0.2), alpha(#${theme.bg}, 0.48)), url("${theme.wallpaper}");
    background-size: cover;
    background-position: center;
  }

  frame.background {
    background-color: alpha(#${theme.surface}, 0.96);
    border: 1px solid alpha(#${theme.accent}, 0.35);
    border-radius: 22px;
    box-shadow: 0 18px 65px alpha(black, 0.38);
    padding: 12px;
  }

  frame.background > grid { padding: 18px 22px; }
  frame.background > grid > label { color: #${theme.muted}; }
  frame.background > grid > label:first-child {
    color: #${theme.cyan};
    font-size: 23px;
    font-weight: 700;
    padding: 6px 0 14px;
  }
  frame.background > label { font-size: 18px; padding: 8px 16px; }

  button, entry, passwordentry {
    color: #${theme.text};
    background-color: #${theme.elevated};
    background-image: none;
    border: 1px solid alpha(#${theme.muted}, 0.25);
    border-radius: ${toString theme.radius}px;
    min-height: 28px;
    padding: 10px 16px;
    box-shadow: none;
  }
  passwordentry entry { background: transparent; border: none; padding: 0; }
  entry:focus-within, passwordentry:focus-within {
    border-color: #${theme.cyan};
    box-shadow: 0 0 0 2px alpha(#${theme.cyan}, 0.15);
  }
  button:hover { background-color: alpha(#${theme.accent}, 0.18); border-color: #${theme.accent}; }
  button:focus-visible { outline: 2px solid #${theme.cyan}; outline-offset: 3px; }
  button:disabled { opacity: 0.5; }

  button.suggested-action {
    color: #${theme.bg};
    background-image: linear-gradient(110deg, #${theme.accent}, #${theme.cyan});
    border-color: transparent;
    font-weight: 700;
    min-width: 110px;
  }
  button.suggested-action:hover { background-image: linear-gradient(110deg, #${theme.cyan}, #${theme.accent}); }
  button.destructive-action {
    color: #${theme.muted};
    background-color: alpha(#${theme.surface}, 0.94);
    border-color: alpha(#${theme.muted}, 0.3);
  }
  button.destructive-action:hover { color: #${theme.red}; border-color: #${theme.red}; }

  popover contents {
    color: #${theme.text};
    background-color: #${theme.surface};
    border: 1px solid #${theme.elevated};
    border-radius: ${toString theme.radius}px;
  }
  row:selected { background-color: alpha(#${theme.accent}, 0.24); }
  infobar { color: #${theme.text}; background-color: #${theme.surface}; border-radius: 12px; }
  infobar.error { color: #${theme.red}; }
''
