vim9script

if did_filetype()
  finish
endif

const shebang = getline(1)
if ('#!/bin/false' == shebang)
  # This is the #! i use for files intended to be sourced, so treat them as zsh
  setfiletype zsh
elseif ('#!/usr/bin/osascript -lJavaScript' == shebang)
  # OSA script using javascript
  setfiletype javascript
endif
