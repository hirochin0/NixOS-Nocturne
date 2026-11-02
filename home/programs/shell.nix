{ ... }: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
    shellAliases = {
      ll = "ls -lah";
      rice = "cd ~/nixos-nocturne";
    };
  };
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      format = "$directory$git_branch$git_status$nix_shell$character";
      directory = { style = "bold cyan"; truncation_length = 3; };
      character = { success_symbol = "[❯](bold purple)"; error_symbol = "[❯](bold red)"; };
      nix_shell = { symbol = "󱄅 "; format = "via [$symbol$state]($style) "; };
    };
  };
}
