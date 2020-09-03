" vimspector - A multi-language debugging system for Vim
" Copyright 2018 Ben Jackson
"
" Licensed under the Apache License, Version 2.0 (the "License");
" you may not use this file except in compliance with the License.
" You may obtain a copy of the License at
"
"   http://www.apache.org/licenses/LICENSE-2.0
"
" Unless required by applicable law or agreed to in writing, software
" distributed under the License is distributed on an "AS IS" BASIS,
" WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
" See the License for the specific language governing permissions and
" limitations under the License.


" Boilerplate {{{
let s:save_cpo = &cpoptions
set cpoptions&vim
" }}}


let s:enabled = vimspector#internal#state#Reset()

function! vimspector#Launch() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.Start()
endfunction

function! vimspector#LaunchWithSettings( settings ) abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.Start( launch_variables = vim.eval( 'a:settings' ) )
endfunction

function! vimspector#Reset() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.Reset()
endfunction

function! vimspector#Restart() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.Restart()
endfunction

function! vimspector#ClearBreakpoints() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.ClearBreakpoints()
endfunction

function! vimspector#ToggleBreakpoint( ... ) abort
  if !s:enabled
    return
  endif
  if a:0 == 0
    let options = {}
  else
    let options = a:1
  endif
  py3 _vimspector_session.ToggleBreakpoint( vim.eval( 'options' ) )
endfunction

function! vimspector#AddFunctionBreakpoint( function, ... ) abort
  if !s:enabled
    return
  endif
  if a:0 == 0
    let options = {}
  else
    let options = a:1
  endif
  py3 _vimspector_session.AddFunctionBreakpoint( vim.eval( 'a:function' ),
                                               \ vim.eval( 'options' ) )
endfunction

function! vimspector#StepOver() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.StepOver()
endfunction

function! vimspector#StepInto() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.StepInto()
endfunction

function! vimspector#StepOut() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.StepOut()
endfunction

function! vimspector#Continue() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.Continue()
endfunction

function! vimspector#Pause() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.Pause()
endfunction

function! vimspector#Stop() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.Stop()
endfunction

function! vimspector#ExpandVariable() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.ExpandVariable()
endfunction

function! vimspector#DeleteWatch() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.DeleteWatch()
endfunction

function! vimspector#GoToFrame() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.ExpandFrameOrThread()
endfunction

function! vimspector#AddWatch( ... ) abort
  if !s:enabled
    return
  endif
  if a:0 == 0
    let expr = input( 'Enter watch expression: ' )
  else
    let expr = a:1
  endif

  if expr ==# ''
    return
  endif

  py3 _vimspector_session.AddWatch( vim.eval( 'expr' ) )
endfunction

function! vimspector#AddWatchPrompt( expr ) abort
  if !s:enabled
    return
  endif
  stopinsert
  setlocal nomodified
  call vimspector#AddWatch( a:expr )
endfunction

function! vimspector#Evaluate( expr ) abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.ShowOutput( 'Console' )
  py3 _vimspector_session.EvaluateConsole( vim.eval( 'a:expr' ) )
endfunction

function! vimspector#EvaluateConsole( expr ) abort
  if !s:enabled
    return
  endif
  stopinsert
  setlocal nomodified
  py3 _vimspector_session.EvaluateConsole( vim.eval( 'a:expr' ) )
endfunction

function! vimspector#ShowOutput( ... ) abort
  if !s:enabled
    return
  endif
  if a:0 == 1
    py3 _vimspector_session.ShowOutput( vim.eval( 'a:1' ) )
  else
    py3 _vimspector_session.ShowOutput( 'Console' )
  endif
endfunction

function! vimspector#ShowOutputInWindow( win_id, category ) abort
  if !s:enabled
    return
  endif
  py3 __import__( 'vimspector',
        \         fromlist = [ 'output' ] ).output.ShowOutputInWindow(
        \           int( vim.eval( 'a:win_id' ) ),
        \           vim.eval( 'a:category' ) )
endfunction

function! vimspector#ToggleLog() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.ToggleLog()
endfunction

function! vimspector#ListBreakpoints() abort
  if !s:enabled
    return
  endif
  py3 _vimspector_session.ListBreakpoints()
endfunction

function! vimspector#CompleteOutput( ArgLead, CmdLine, CursorPos ) abort
  if !s:enabled
    return
  endif
  let buffers = py3eval( '_vimspector_session.GetOutputBuffers() '
                       \ . ' if _vimspector_session else []' )
  return join( buffers, "\n" )
endfunction

py3 <<EOF
def _vimspector_GetExprCompletions( CmdLine, CursorPos ):
  if not _vimspector_session:
    return []

  # FIXME
  # Curiously, it seems that CursorPos is 0-based here and that's actually what
  # the servers want/need ?
  return [ i.get( 'text' ) or i[ 'label' ]
           for i in _vimspector_session.GetCompletionsSync( CmdLine,
                                                            CursorPos ) ]
EOF

function! vimspector#CompleteExpr( ArgLead, CmdLine, CursorPos ) abort
  if !s:enabled
    return
  endif
  return join( py3eval( '_vimspector_GetExprCompletions( '
                      \.'  vim.eval( "a:CmdLine" ),'
                      \.'  int( vim.eval( "a:CursorPos" ) ) + 1 )' ),
             \ "\n" )
endfunction

let s:latest_completion_request = {}

function! vimspector#CompleteFuncSync( prompt, find_start, query ) abort
  if py3eval( 'not _vimspector_session' )
    return []
  endif

  if a:find_start

    " We're busy
    if !empty( s:latest_completion_request )
      return -1
    endif

    let line = getline( line( '.' ) )[ len( a:prompt ) : ]
    let col = col( '.' ) - len( a:prompt )
    let s:latest_completion_request.items =
          \ py3eval( '_vimspector_session.GetCompletionsSync( '
                   \.'  vim.eval( "line" ), '
                   \.'  int( vim.eval( "col" ) ) )' )
    let s:latest_completion_request.line = line
    let s:latest_completion_request.col = col

    let start_pos = col
    for item in s:latest_completion_request.items
      if !has_key( item, 'start' )
        let item.start = col
      else
        " For some reason, the returned start value is 0-indexed even though we
        " use columnsStartAt1
        " TODO need to check this with the other servers that exist
        let item.start += 1
      endif
      " TODO/FIXME. I don't think it's possible to implement the 'length'
      " parameter, using vim's completion system
      " if !has_key( item, 'length' )
      "   let item.length = 0
      " endif
      if !has_key( item, 'text' )
        let item.text = item.label
      endif

      if item.start < start_pos
        let start_pos = item.start
      endif
    endfor

    let s:latest_completion_request.start_pos = start_pos
    let s:latest_completion_request.prompt = a:prompt

    " start_pos is 1-based and the return of findstart is 0-based
    return ( start_pos + len( a:prompt ) ) - 1
  else
    let items = []
    let pfxlen = len( s:latest_completion_request.prompt )
    for item in s:latest_completion_request.items
      if item.start > s:latest_completion_request.start_pos
        " fix up the text (insert anything that is already present in the line
        " that would be erased by the fixed-up earlier start position)
        "
        " both start_pos and item.start are 1-based
        let item.text = s:latest_completion_request.text[
              \ s:latest_completion_request.start_pos + pfxlen - 1 :
              \  item.start + pfxlen - 1 ] . item.text
      endif

      call add( items, { 'word': item.text,
                       \ 'abbr': item.label,
                       \ 'menu': get( item, 'type', '' ),
                       \ 'icase': 1,
                       \ } )
    endfor
    let s:latest_completion_request = {}
    return { 'words': items, 'refresh': 'always' }
  endif
endfunction

function! vimspector#OmniFuncWatch( find_start, query ) abort
  return vimspector#CompleteFuncSync( 'Expression: ', a:find_start, a:query )
endfunction

function! vimspector#OmniFuncConsole( find_start, query ) abort
  return vimspector#CompleteFuncSync( '> ', a:find_start, a:query )
endfunction

function! vimspector#Install( bang, ... ) abort
  if !s:enabled
    return
  endif
  let prefix = vimspector#internal#state#GetAPIPrefix()
  py3 __import__( 'vimspector',
        \         fromlist = [ 'installer' ] ).installer.RunInstaller(
        \           vim.eval( 'prefix' ),
        \           vim.eval( 'a:bang' ) == '!',
        \           *vim.eval( 'a:000' ) )
endfunction

function! vimspector#CompleteInstall( ArgLead, CmdLine, CursorPos ) abort
  if !s:enabled
    return
  endif
  return py3eval( '"\n".join('
                \ .   '__import__( "vimspector", fromlist = [ "gadgets" ] )'
                \ .   '.gadgets.GADGETS.keys() '
                \ . ')' )
endfunction

function! vimspector#Update( bang, ... ) abort
  if !s:enabled
    return
  endif

  let prefix = vimspector#internal#state#GetAPIPrefix()
  py3 __import__( 'vimspector',
        \         fromlist = [ 'installer' ] ).installer.RunUpdate(
        \           vim.eval( 'prefix' ),
        \           vim.eval( 'a:bang' ) == '!',
        \           *vim.eval( 'a:000' ) )
endfunction

function! vimspector#AbortInstall() abort
  if !s:enabled
    return
  endif

  let prefix = vimspector#internal#state#GetAPIPrefix()
  py3 __import__( 'vimspector', fromlist = [ 'installer' ] ).installer.Abort()
endfunction


" Boilerplate {{{
let &cpoptions=s:save_cpo
unlet s:save_cpo
" }}}
