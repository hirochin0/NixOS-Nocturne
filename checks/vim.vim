packloadall
filetype plugin indent on
syntax enable
call assert_equal(1, &number)
call assert_equal(1, &undofile)
call assert_equal(0, &modeline)
call assert_match(':Files', maparg(' ff', 'n'))
for cmd in ['Files', 'Rg', 'Buffers', 'Git', 'Gdiffsplit', 'Commentary']
  call assert_equal(2, exists(':' . cmd), cmd)
endfor
call assert_true(executable(fzf#exec()))
call assert_equal(1, get(g:, 'loaded_gitgutter', 0))
new example.nix
call assert_equal('nix', &filetype)
call assert_equal(2, &shiftwidth)
call assert_equal(2, &tabstop)
call assert_true(!empty(&syntax))
new example.c
call setline(1, 'int value = 1;')
normal gcc
call assert_equal('/* int value = 1; */', getline(1))
normal gcc
call assert_equal('int value = 1;', getline(1))
call setline(1, 'hello')
call cursor(1, 1)
normal ysiw"
call assert_equal('"hello"', getline(1))
call assert_equal($XDG_STATE_HOME . '/vim/undo', &undodir)
if len(v:errors)
  call writefile(v:errors, '/dev/stderr')
  cquit
endif
qa!
