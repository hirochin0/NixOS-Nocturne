{ pkgs, theme, ... }: {
  home.packages = [ pkgs.fzf ];
  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      fzf-vim
      vim-fugitive
      vim-gitgutter
      vim-surround
      vim-commentary
      vim-nix
    ];
    settings = {
      number = true;
      mouse = "a";
      expandtab = true;
      tabstop = 4;
      shiftwidth = 4;
      ignorecase = true;
      smartcase = true;
      hidden = true;
      undofile = true;
      modeline = false;
      background = "dark";
    };
    extraConfig = ''
      set encoding=utf-8
      set incsearch hlsearch
      set cursorline signcolumn=yes
      set splitright splitbelow
      set laststatus=2
      set updatetime=300
      if has('termguicolors')
        set termguicolors
      endif
      if has('clipboard')
        set clipboard=unnamedplus
      endif

      let mapleader = " "
      nnoremap <silent> <leader>ff :Files<CR>
      nnoremap <leader>fg :Rg<Space>
      nnoremap <silent> <leader>fb :Buffers<CR>
      nnoremap <silent> <leader>gs :Git<CR>
      nnoremap <silent> <leader>gd :Gdiffsplit<CR>
      nnoremap <silent> <leader>e :Explore<CR>
      nnoremap <silent> <leader><Space> :nohlsearch<CR>
      let g:fzf_layout = { 'down': '40%' }
      let g:netrw_banner = 0
      let g:netrw_liststyle = 3

      " Undo and history are user data, not files in the Nix store.
      let s:state = (empty($XDG_STATE_HOME) ? expand('~/.local/state') : $XDG_STATE_HOME) . '/vim'
      call mkdir(s:state . '/undo', 'p', 0700)
      let &undodir = s:state . '/undo'
      let &viminfofile = s:state . '/viminfo'

      augroup nocturne_vim
        autocmd!
        autocmd FileType nix setlocal tabstop=2 shiftwidth=2 softtabstop=2
        autocmd ColorScheme * call NocturneHighlights()
      augroup END
      function! NocturneHighlights() abort
        highlight Normal guifg=#${theme.text} guibg=NONE
        highlight LineNr guifg=#${theme.muted} guibg=NONE
        highlight CursorLine guibg=#${theme.surface}
        highlight CursorLineNr guifg=#${theme.cyan} guibg=#${theme.surface}
        highlight SignColumn guibg=NONE
        highlight Visual guibg=#${theme.elevated}
        highlight Search guifg=#${theme.bg} guibg=#${theme.cyan}
        highlight StatusLine guifg=#${theme.text} guibg=#${theme.elevated}
        highlight StatusLineNC guifg=#${theme.muted} guibg=#${theme.surface}
      endfunction
      call NocturneHighlights()
    '';
  };
}
