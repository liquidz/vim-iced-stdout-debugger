let s:save_cpo = &cpoptions
set cpoptions&vim

let s:saved_view = ''
let s:supported_types = {'n': 'next', 'c': 'continue', 'q': 'quit', 'j': 'inject' }
let s:reversed_supported_types = {}
for k in keys(s:supported_types)
  let s:reversed_supported_types[s:supported_types[k]] = k
endfor

function! s:ensure_dict(x) abort
  let t = type(a:x)
  if t == v:t_dict
    return a:x
  elseif t == v:t_list
    let result = {}
    for x in a:x
      call extend(result, s:ensure_dict(x))
    endfor
    return result
  else
    return {}
  endif
endfunction

function! iced#nrepl#debug#stdout#start(resp) abort
  if type(s:saved_view) != v:t_dict
    let s:saved_view = iced#util#save_context()
  endif

  " NOTE: Disable temporarily.
  "       Enable again at iced#nrepl#debug#quit.
  let &eventignore = 'CursorHold,CursorHoldI,CursorMoved,CursorMovedI'

  let resp = s:ensure_dict(a:resp)
  call iced#nrepl#debug#default#move_cursor_and_set_highlight(resp)
  let debug_texts = iced#nrepl#debug#default#generate_debug_text(resp)

  if ! iced#buffer#stdout#is_visible()
    call iced#buffer#stdout#open()
  endif


  call iced#buffer#stdout#append(';; Debugging')
  for text in debug_texts
    call iced#buffer#stdout#append(text)
  endfor

  let input_type = resp['input-type']
  let input_type_type = type(input_type)

  if input_type_type == v:t_dict
    let ks = filter(sort(keys(input_type)), {_, v -> has_key(s:supported_types, v)})
    let prompt = join(map(ks, {_, k -> printf('(%s)%s', k, input_type[k])}), ', ')

  elseif type(input_type) == v:t_list
    "" cider-nrepl 0.24.0 or later???
    let ks = filter(sort(copy(input_type)), {_, v -> has_key(s:reversed_supported_types, v)})
    let prompt = join(map(ks, {_, k -> printf('(%s)%s', s:reversed_supported_types[k], k)}), ', ')

  elseif has_key(resp, 'prompt') && !empty(resp['prompt'])
    let prompt = resp['prompt']
  endif

  redraw
  let in = trim(iced#system#get('io').input(prompt . "\n: "))
  if input_type_type == v:t_dict || input_type_type == v:t_list
    let in = ':'.get(s:supported_types, in, 'quit')
  endif
  call iced#nrepl#op#cider#debug#input(resp['key'], in)
endfunction " }}}

function! iced#nrepl#debug#stdout#quit() abort
  " NOTE: Enable autocmds
  let &eventignore = ''

  if type(s:saved_view) == v:t_dict
    let s:debug_key = ''
    call iced#buffer#stdout#append(';; Quit')
    call iced#highlight#clear()
    call iced#util#restore_context(s:saved_view)
    let s:saved_view = ''
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
