vim9script

g:colors_name = expand('<sfile>:t:r')

# Minimalist colour scheme

# Just use the 16 terminal colors
&t_Co = "16"
# But turn on undercurl support
&t_Cs = "\e[4:3m"
&t_Ce = "\e[4:0m"

highlight Added ctermfg=2
highlight Comment ctermfg=13
highlight Constant ctermfg=3
highlight Directory ctermfg=4
highlight Identifier cterm=none ctermfg=9
highlight LineNr cterm=none ctermfg=11
highlight Preproc ctermfg=5
highlight Removed ctermfg=1
highlight Special ctermfg=2
highlight SpecialKey ctermfg=1
highlight Statement ctermfg=6
highlight Type ctermfg=4

# Whatever sets up the basic spelling sets ctermbg, so we need to clear it for these
highlight SpellBad ctermbg=none cterm=undercurl  ctermul=1
highlight SpellCap ctermbg=none cterm=undercurl ctermul=4
highlight SpellLocal ctermbg=none cterm=undercurl ctermul=2
highlight SpellRare ctermbg=none cterm=undercurl ctermul=3
