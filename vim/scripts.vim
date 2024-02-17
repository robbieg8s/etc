if did_filetype()
  finish
endif

" This is the #! i use for files intended to be sourced, so treat them as zsh
if getline(1) == '#!/bin/false'
  setfiletype zsh
endif

