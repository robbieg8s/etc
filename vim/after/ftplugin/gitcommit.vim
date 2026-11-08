" Text options for commits - autoformatting and lists, plus standard width
set formatlistpat=\\s*-\\?\\s*\\ze.
set formatoptions=ant
set textwidth=72

" Make it easier to write bulleted lists with formatoptions by auto inserting the
" space after a list starting hyphen, and suppressing the extra space i tend to type
inoremap <expr> - <SID>AddSpaceAfterStartOfLineHyphen()
inoremap <expr> <Space> <SID>SuppressSpaceAfterAddedSpace()

function! s:AddSpaceAfterStartOfLineHyphen()
  if (1 == getpos(".")[2])
    return "- "
  else
    return "-"
  endif
endfunction

function! s:SuppressSpaceAfterAddedSpace()
  if ((3 == getpos(".")[2]) && ("- " == getline(".")))
    return ""
  else
    return " "
  endif
endfunction

" Ensure a blank line ahead of the git help, which helps stop over eager autoformat
let s:pos = getpos('.')
let s:help_line = search('^#')
if (0 != s:help_line)
  call setpos('.', [ 0, s:help_line - 1, 1, 1 ] )
  if ((2 == s:help_line) || ("" != getline(".")))
    call append('.', [ '' ])
  endif
  call setpos('.', s:pos)
else
  " Restore cursor position - this is for tig's benefit where this filetype is used,
  " but there is no git help line to work around. We could explicit set the tig state
  " if needed, but inferring it from the help line is ok for a first cut. We need to
  " validate, since we re-use the filename COMMIT_EDITMSG in this case.
  if (line("'\"") <= line('$'))
    normal! g'"
  endif

endif
