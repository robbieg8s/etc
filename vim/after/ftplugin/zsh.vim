" The :ZshKeywordPrg to use run-help doesn't work well for me - it leaves an empty buffer
" behind after running that i need to close, and also run-help doesn't find zsh specific help.
" For now, just put back man, and remap K to auto hit enter after man completes.
set keywordprg=man
" It might be nice to only <cr> if man exited 0, by testing v:shell_error?
noremap K K<cr>
