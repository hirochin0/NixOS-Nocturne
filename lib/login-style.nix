{ pkgs, theme }:
let
  # Pre-render a static blur: no live blur or video loop in the greeter.
  background = pkgs.runCommand "nocturne-login-background.png" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    magick ${theme.wallpaper} -blur 0x14 "$out"
  '';
in pkgs.writeText "nocturne-login.css" ''
  @define-color accent_color #${theme.cyan};
  @define-color accent_bg_color #${theme.accent};
  @define-color accent_fg_color #${theme.bg};
  @define-color window_bg_color #${theme.bg};
  @define-color window_fg_color #${theme.text};

  window {
    color: #${theme.text};
    background-color: #${theme.bg};
    background-image: linear-gradient(alpha(#${theme.bg}, 0.28), alpha(#${theme.bg}, 0.28)), url("${background}");
    background-size: cover;
    background-position: center;
  }

  frame, .lock-layout {
    background: transparent;
    border: none;
    box-shadow: none;
  }
  .lock-clock > label {
    font-family: "${theme.font}";
    font-size: 112px;
    font-weight: 400;
    color: #${theme.text};
  }
  .lock-layout > grid { margin-left: 24px; margin-right: 24px; }
  grid > passwordentry, grid > entry { min-width: 264px; }
  .lock-identity { color: #${theme.muted}; font-size: 14px; }
  .lock-prompt { color: #${theme.muted}; font-size: 13px; }

  button, entry, passwordentry {
    color: #${theme.text};
    background-color: alpha(#${theme.surface}, 0.94);
    background-image: none;
    border: 1px solid alpha(#${theme.muted}, 0.3);
    border-radius: ${toString theme.radius}px;
    min-height: 32px;
    padding: 10px 14px;
    box-shadow: none;
  }
  passwordentry, entry { border: 2px solid #${theme.accent}; }
  passwordentry entry { background: transparent; border: none; padding: 0; }
  entry:focus-within, passwordentry:focus-within { border-color: #${theme.cyan}; }
  button:hover { border-color: #${theme.accent}; }
  button:focus-visible { outline: 2px solid #${theme.cyan}; outline-offset: 2px; }
  button:disabled { opacity: 0.5; }

  button.suggested-action {
    color: #${theme.cyan};
    background: transparent;
    border-color: transparent;
    font-weight: 500;
    min-width: 24px;
    padding: 10px;
    border: 1px solid alpha(#${theme.cyan}, 0.45);
  }
  button.suggested-action:hover { background-color: alpha(#${theme.cyan}, 0.08); }
  button.power-action {
    color: #${theme.muted};
    background: transparent;
    border-color: transparent;
    padding: 6px 12px;
    font-size: 13px;
  }
  button.power-action:hover { color: #${theme.text}; background-color: alpha(#${theme.surface}, 0.65); }

  popover contents {
    color: #${theme.text};
    background-color: #${theme.surface};
    border: 1px solid #${theme.elevated};
    border-radius: ${toString theme.radius}px;
  }
  row:selected { background-color: alpha(#${theme.accent}, 0.24); }
  infobar { color: #${theme.red}; background-color: alpha(#${theme.surface}, 0.9); border-radius: 12px; }
''
