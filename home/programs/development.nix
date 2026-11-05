{ desktop, ... }: {
  home.packages = [ desktop.codex desktop.google-chrome desktop.neofetch desktop.discord ];
  programs.vscode = {
    enable = true;
    package = desktop.vscode;
    profiles.default.userSettings = {
      "editor.fontFamily" = "'JetBrainsMono Nerd Font', monospace";
      "editor.tabSize" = 2;
      "files.insertFinalNewline" = true;
      "telemetry.telemetryLevel" = "off";
      "update.mode" = "none";
    };
  };
  xdg.desktopEntries.chatgpt = {
    name = "ChatGPT";
    comment = "ChatGPT in Google Chrome";
    exec = "${desktop.google-chrome}/bin/google-chrome-stable --app=https://chatgpt.com";
    icon = "google-chrome";
    terminal = false;
    categories = [ "Network" ];
  };
}
