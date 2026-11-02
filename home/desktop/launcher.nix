{ theme, ... }: {
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "${theme.font}:size=12";
        terminal = "kitty";
        prompt = "❯  ";
        width = 42;
        lines = 8;
        horizontal-pad = 24;
        vertical-pad = 20;
        inner-pad = 10;
        icons-enabled = true;
      };
      colors = {
        background = "${theme.bg}f5";
        text = "${theme.text}ff";
        match = "${theme.cyan}ff";
        selection = "${theme.elevated}ff";
        selection-text = "${theme.text}ff";
        selection-match = "${theme.accent}ff";
        border = "${theme.accent}dd";
      };
      border = { width = 2; radius = theme.radius; };
    };
  };
}
