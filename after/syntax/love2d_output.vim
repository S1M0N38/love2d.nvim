" Syntax highlighting for the love2d_output filetype.
" Used by the LÖVE output panel (lua/love2d/output.lua).

if exists("b:current_syntax")
  finish
endif

" Error lines — contain ": error:" pattern (from custom love.errorhandler)
syntax match love2dOutputError ".*: error:.*" contains=NONE

" Exit messages
syntax match love2dOutputExit "^\[Process exited with code \d\+\]$"

highlight default link love2dOutputError ErrorMsg
highlight default link love2dOutputExit Comment

let b:current_syntax = "love2d_output"
