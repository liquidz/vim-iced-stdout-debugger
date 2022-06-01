if exists('g:vim_iced_stdout_debugger_loaded')
  finish
endif

if !exists('g:vim_iced_version')
      \ || g:vim_iced_version < 20500
  echoe 'iced-stdout-debugger requires vim-iced v2.5.0 or later.'
  finish
endif

let g:vim_iced_stdout_debugger_loaded = 1

let s:last_debugger = 'default'
function! s:toggle_debugger() abort
  if g:iced#debug#debugger !=# 'stdout'
    let s:last_debugger = g:iced#debug#debugger
    let g:iced#debug#debugger = 'stdout'
  else
    let g:iced#debug#debugger = s:last_debugger
  endif

  return iced#message#info_str(printf('Switch debugger to "%s".', g:iced#debug#debugger))
endfunction

command! IcedToggleStdoutDebugger call s:toggle_debugger()

if !exists('g:iced#palette')
  let g:iced#palette = {}
endif
call extend(g:iced#palette, {
      \ 'ToggleStdoutDebugger': ':IcedToggleStdoutDebugger',
      \ })
