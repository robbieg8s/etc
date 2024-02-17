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
  end
endfunction

function! s:SuppressSpaceAfterAddedSpace()
  if ((3 == getpos(".")[2]) && ("- " == getline(".")))
    return ""
  else
    return " "
  end
endfunction

" Ensure a blank line ahead of the git help, which helps stop over eager autoformat
let s:pos = getpos('.')
let s:help_line = search('^#')
if (0 != s:help_line)
  call setpos('.', [ 0, s:help_line - 1, 1, 1 ] )
  if ((2 == s:help_line) || ("" != getline(".")))
    call append('.', [ '' ])
  end
  call setpos('.', s:pos)
end
