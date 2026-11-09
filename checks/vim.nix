{ pkgs, home-manager, theme }:
let
  home = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = { inherit theme; };
    modules = [
      ../home/programs/vim.nix
      {
        home.username = "vim-test";
        home.homeDirectory = "/home/vim-test";
        home.stateVersion = "26.05";
      }
    ];
  };
in pkgs.runCommand "nocturne-vim-check" {
  nativeBuildInputs = [ home.config.programs.vim.package pkgs.fzf pkgs.ripgrep ];
} ''
  export HOME="$TMPDIR/home"
  export XDG_STATE_HOME="$HOME/.local/state"
  mkdir -p "$HOME"
  # Run twice to check reuse of the persistent undo/history directories.
  vim -i NONE -n -es -S ${./vim.vim}
  vim -i NONE -n -es -S ${./vim.vim}
  touch "$out"
''
