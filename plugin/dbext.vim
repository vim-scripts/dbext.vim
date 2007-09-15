" dbext.vim - Commn Database Utility
" Copyright (C) 2002-7, Peter Bagyinszki, David Fishburn
"
" ---------------------------------------------------------------
" Version:       5.20
" Maintainer:    David Fishburn <fishburn@ianywhere.com>
" Authors:       Peter Bagyinszki <petike1@dpg.hu>
"                David Fishburn <fishburn@ianywhere.com>
" Last Modified: Sat 15 Sep 2007 11:09:30 PM Eastern Daylight Time
" Based On:      sqlplus.vim (author: Jamis Buck)
" Created:       2002-05-24
" Homepage:      http://vim.sourceforge.net/script.php?script_id=356
" Contributors:  Joerg Schoppet <joerg.schoppet@web.de>
"                Hari Krishna Dara <hari_vim@yahoo.com>
"                Ron Aaron
"
" SourceForge:  $Revision: 1.38 $
"
" Help:         :h dbext.txt 
"
" This program is free software; you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation; either version 2 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program; if not, write to the Free Software
" Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

if exists('g:loaded_dbext') || &cp
    finish
endif
if v:version < 700
    echomsg "dbext: Version 4.00 or higher requires Vim7.  Version 3.50 can stil be used with Vim6."
    finish
endif
let g:loaded_dbext = 520

" Commands {{{
command! -nargs=+ DBExecSQL         :call dbext#DB_execSql(<q-args>)
command! -nargs=+ DBExecSQLTopX     :call dbext#DB_execSqlTopX(<q-args>)
command! -nargs=0 DBConnect         :call dbext#DB_connect()
command! -nargs=0 DBDisconnect      :call dbext#DB_disconnect()
command! -nargs=0 DBCommit          :call dbext#DB_commit()
command! -nargs=0 DBRollback        :call dbext#DB_rollback()
command! -nargs=0 DBListConnections :call dbext#DB_getListConnections()
command! -range -nargs=0 DBExecRangeSQL <line1>,<line2>call dbext#DB_execRangeSql()
command! -nargs=+ Call              :call dbext#DB_execSql("call " . <q-args>)
command! -nargs=+ Select            :call dbext#DB_execSql("select " . <q-args>)
command! -nargs=+ Update            :call dbext#DB_execSql("update " . <q-args>)
command! -nargs=+ Insert            :call dbext#DB_execSql("insert " . <q-args>)
command! -nargs=+ Delete            :call dbext#DB_execSql("delete " . <q-args>)
command! -nargs=+ Drop              :call dbext#DB_execSql("drop " . <q-args>)
command! -nargs=+ Alter             :call dbext#DB_execSql("alter " . <q-args>)
command! -nargs=+ Create            :call dbext#DB_execSql("create " . <q-args>)
command! -nargs=1 DBSetOption       :call dbext#DB_setMultipleOptions(<q-args>)
command! -nargs=? DBGetOption       :echo DB_listOption(<q-args>)
command! -nargs=* -complete=customlist,dbext#DB_settingsComplete DBSetOption :call dbext#DB_setMultipleOptions(<q-args>)
command! -nargs=* -complete=customlist,dbext#DB_settingsComplete DBGetOption :echo DB_listOption(<q-args>)

if !exists(':DBExecVisualSQL')
    command! -nargs=0 -range DBExecVisualSQL :call dbext#DB_execSql(DB_getVisualBlock())
    vmap <unique> <script> <Plug>DBExecVisualSQL :DBExecVisualSQL<CR>
endif
if !exists(':DBExecVisualSQLTopX')
    command! -nargs=0 -range DBExecVisualSQLTopX :call dbext#DB_execSqlTopX(DB_getVisualBlock())
    vmap <unique> <script> <Plug>DBExecVisualSQLTopX :DBExecVisualSQLTopX<CR>
endif
if !exists(':DBExecSQLUnderCursor')
    command! -nargs=0 DBExecSQLUnderCursor
                \ :call dbext#DB_execSql(dbext#DB_getQueryUnderCursor())
    nmap <unique> <script> <Plug>DBExecSQLUnderCursor :DBExecSQLUnderCursor<CR>
endif
if !exists(':DBExecSQLUnderCursorTopX')
    command! -nargs=0 DBExecSQLUnderCursorTopX
                \ :call dbext#DB_execSqlTopX(dbext#DB_getQueryUnderCursor())
    nmap <unique> <script> <Plug>DBExecSQLUnderCursorTopX :DBExecSQLUnderCursorTopX<CR>
endif
if !exists(':DBExecSQL')
    command! -nargs=0 DBExecSQL
                \ :call dbext#DB_execSql(dbext#DB_parseQuery(dbext#DB_getQueryUnderCursor()))
    nmap <unique> <script> <Plug>DBExecSQL :DBExecSQL<CR>
endif
if !exists(':DBSelectFromTable')
    command! -nargs=* -range DBSelectFromTable
                \ :call dbext#DB_execSqlWithDefault("select * from ", <f-args>)
    nmap <unique> <script> <Plug>DBSelectFromTable :DBSelectFromTable<CR>
endif
if !exists(':DBSelectFromTableWithWhere')
    command! -nargs=0 DBSelectFromTableWithWhere
                \ :call dbext#DB_execSql("select * from " .
                \ expand("<cword>") . " where " .
                \ input("Please enter where clause: "))
    nmap <unique> <script> <Plug>DBSelectFromTableWithWhere
                \ :DBSelectFromTableWithWhere<CR>
endif
if !exists(':DBSelectFromTableAskName')
    command! -nargs=0 DBSelectFromTableAskName
                \ :call dbext#DB_selectTablePrompt()
    nmap <unique> <script> <Plug>DBSelectFromTableAskName
                \ :DBSelectFromTableAskName<CR>
endif
if !exists(':DBSelectFromTableTopX')
    command! -nargs=* -range DBSelectFromTableTopX
                \ :call dbext#DB_execSqlTopX(dbext#DB_getSqlWithDefault("select * from ", <f-args>))
    nmap <unique> <script> <Plug>DBSelectFromTableTopX :DBSelectFromTableTopX<CR>
endif
if !exists(':DBDescribeTable')
    command! -nargs=* -range DBDescribeTable
                \ :call dbext#DB_describeTable(<f-args>)
    nmap <unique> <script> <Plug>DBDescribeTable :DBDescribeTable<CR>
endif
if !exists(':DBDescribeTableAskName')
    command! -nargs=0 DBDescribeTableAskName
                \ :call dbext#DB_describeTablePrompt()
    nmap <unique> <script> <Plug>DBDescribeTableAskName
                \ :DBDescribeTableAskName<CR>
endif
if !exists(':DBDescribeProcedure')
    command! -nargs=* -range DBDescribeProcedure
                \ :call dbext#DB_describeProcedure(<f-args>)
    nmap <unique> <script> <Plug>DBDescribeProcedure :DBDescribeProcedure<CR>
endif
if !exists(':DBDescribeProcedureAskName')
    command! -nargs=0 DBDescribeProcedureAskName
                \ :call dbext#DB_describeProcedurePrompt()
    nmap <unique> <script> <Plug>DBDescribeProcedureAskName
                \ :DBDescribeProcedureAskName<CR>
endif
if !exists(':DBPromptForBufferParameters')
    command! -nargs=0 DBPromptForBufferParameters
                \ :call dbext#DB_execFuncWCheck('promptForParameters')
    nmap <unique> <script> <Plug>DBPromptForBufferParameters
                \ :DBPromptForBufferParameters<CR>
endif
if !exists(':DBListColumn')
    command! -nargs=* DBListColumn
                \ :call DB_getListColumn(<f-args>)
    nmap <unique> <script> <Plug>DBListColumn :DBListColumn<CR>
endif
if !exists(':DBListTable')
    command! -nargs=? DBListTable
                \ :call dbext#DB_getListTable(<f-args>)
    nmap <unique> <script> <Plug>DBListTable
                \ :DBListTable<CR>
endif
if !exists(':DBListProcedure')
    command! -nargs=? DBListProcedure
                \ :call dbext#DB_getListProcedure(<f-args>)
    nmap <unique> <script> <Plug>DBListProcedure
                \ :DBListProcedure<CR>
endif
if !exists(':DBListView')
    command! -nargs=? DBListView
                \ :call dbext#DB_getListView(<f-args>)
    nmap <unique> <script> <Plug>DBListView
                \ :DBListView<CR>
endif 
if !exists(':DBCompleteTables')
    command! -nargs=0 -bang DBCompleteTables
                \ :call DB_DictionaryCreate( <bang>0, 'Table' )
end
if !exists(':DBCompleteProcedures')
    command! -nargs=0 -bang DBCompleteProcedures
                \ :call DB_DictionaryCreate( <bang>0, 'Procedure' )
end
if !exists(':DBCompleteViews')
    command! -nargs=0 -bang DBCompleteViews
                \ :call DB_DictionaryCreate( <bang>0, 'View' )
end
if !exists(':DBCheckModeline')
    command! -nargs=0 DBCheckModeline
                \ :call dbext#DB_checkModeline()
end
if !exists(':DBRefreshResult')
    command! -nargs=0 DBRefreshResult
                \ :call dbext#DB_runPrevCmd()
end
if !exists(':DBOrientationToggle')
    command! -nargs=0 DBOrientationToggle
                \ :call dbext#DB_orientationToggle()
    nmap <unique> <script> <Plug>DBOrientationToggle :DBOrientationToggle<CR>
end
if !exists(':DBHistory')
    command! -nargs=0 DBHistory
                \ :call dbext#DB_historyList()
    nmap <unique> <script> <Plug>DBHistory :DBHistory<CR>
end
if !exists(':DBCloseResults')
    command! -nargs=0 DBCloseResults
                \ :call dbext#DB_closeWindow('%')
end
"}}}
" Mappings {{{
if !hasmapto('<Plug>DBExecVisualSQL')
    vmap <unique> <Leader>se <Plug>DBExecVisualSQL
endif
if !hasmapto('<Plug>DBExecVisualSQLTopX')
    vmap <unique> <Leader>sE <Plug>DBExecVisualSQLTopX
endif
if !hasmapto('<Plug>DBExecSQLUnderCursor')
    nmap <unique> <Leader>se <Plug>DBExecSQLUnderCursor
endif
if !hasmapto('<Plug>DBExecSQLUnderCursorTopX')
    nmap <unique> <Leader>sE <Plug>DBExecSQLUnderCursorTopX
endif
if !hasmapto('<Plug>DBExecSQL')
    nmap <unique> <Leader>sq <Plug>DBExecSQL
endif
if !hasmapto('DBExecRangeSQL')
    nmap <unique> <silent> <Leader>sea :1,$DBExecRangeSQL<CR>
    nmap <unique> <silent> <Leader>sel :.,.DBExecRangeSQL<CR>
endif
if !hasmapto('<Plug>DBSelectFromTable')
    nmap <unique> <Leader>st <Plug>DBSelectFromTable
    vmap <unique> <silent> <Leader>st
                \ :<C-U>exec 'DBSelectFromTable '.DB_getVisualBlock()<CR>
endif
if !hasmapto('<Plug>DBSelectFromTableWithWhere')
    nmap <unique> <Leader>stw <Plug>DBSelectFromTableWithWhere
endif
if !hasmapto('<Plug>DBSelectFromTableAskName')
    nmap <unique> <Leader>sta <Plug>DBSelectFromTableAskName
endif
if !hasmapto('<Plug>DBSelectFromTableTopX')
    nmap <unique> <Leader>sT <Plug>DBSelectFromTableTopX
    vmap <unique> <silent> <Leader>sT
                \ :<C-U>exec 'DBSelectFromTableTopX '.DB_getVisualBlock()<CR>
endif
if !hasmapto('<Plug>DBDescribeTable')
    nmap <unique> <Leader>sdt <Plug>DBDescribeTable
    vmap <unique> <silent> <Leader>sdt
                \ :<C-U>exec 'DBDescribeTable '.DB_getVisualBlock()<CR>
endif
if !hasmapto('<Plug>DBDescribeTableAskName')
    nmap <unique> <Leader>sdta <Plug>DBDescribeTableAskName
endif
if !hasmapto('<Plug>DBDescribeProcedure')
    nmap <unique> <Leader>sdp <Plug>DBDescribeProcedure
    vmap <unique> <silent> <Leader>sdp
                \ :<C-U>exec 'DBDescribeProcedure '.DB_getVisualBlock()<CR>
endif
if !hasmapto('<Plug>DBDescribeProcedureAskName')
    nmap <unique> <Leader>sdpa <Plug>DBDescribeProcedureAskName
endif
if !hasmapto('<Plug>DBPromptForBufferParameters')
    nmap <unique> <Leader>sbp <Plug>DBPromptForBufferParameters
endif
if !hasmapto('<Plug>DBListColumn')
    nmap <unique> <Leader>slc <Plug>DBListColumn
    vmap <unique> <silent> <Leader>slc
                \ :<C-U>exec 'DBListColumn '.DB_getVisualBlock()<CR>
endif
if !hasmapto('<Plug>DBListTable')
    nmap <unique> <Leader>slt <Plug>DBListTable
endif
if !hasmapto('<Plug>DBListProcedure')
    nmap <unique> <Leader>slp <Plug>DBListProcedure
endif
if !hasmapto('<Plug>DBListView')
    nmap <unique> <Leader>slv <Plug>DBListView
endif
if !hasmapto('<Plug>DBListColumn')
    nmap <unique> <Leader>stcl <Plug>DBListColumn
    vmap <unique> <silent> <Leader>stcl
                \ :<C-U>exec 'DBListColumn '.DB_getVisualBlock()<CR>
endif
if !hasmapto('<Plug>DBHistory')
    nmap <unique> <Leader>sh <Plug>DBHistory
endif
if !hasmapto('<Plug>DBOrientationToggle')
    nmap <unique> <Leader>so <Plug>DBOrientationToggle
endif
"}}}
" Menus {{{
if has("gui_running") && has("menu")
    vnoremenu <script> Plugin.dbext.Execute\ SQL\ (Visual\ selection) :DBExecVisualSQL<CR>
    noremenu <script> Plugin.dbext.Execute\ SQL\ (Under\ cursor) :DBExecSQLUnderCursor<CR>
    vnoremenu <script> Plugin.dbext.Execute\ SQL\ TopX\ (Visual\ selection) :DBExecVisualSQLTopX<CR>
    noremenu <script> Plugin.dbext.Execute\ SQL\ TopX\ (Under\ cursor) :DBExecSQLUnderCursorTopX<CR>
    " noremenu <script> Plugin.dbext.Execute\ SQL :DBExecSQLUnderCursor<CR>
    noremenu <script> Plugin.dbext.Select\ Table
                \ :DBSelectFromTable<CR>
    inoremenu <script> Plugin.dbext.Select\ Table
                \ <C-O>:DBSelectFromTable<CR>
    vnoremenu <script> Plugin.dbext.Select\ Table
                \ :<C-U>exec "DBSelectFromTable ".DB_getVisualBlock()<CR>
    noremenu <script> Plugin.dbext.Select\ Table\ TopX
                \ :DBSelectFromTableTopX<CR>
    inoremenu <script> Plugin.dbext.Select\ Table\ TopX
                \ <C-O>:DBSelectFromTableTopX<CR>
    vnoremenu <script> Plugin.dbext.Select\ Table\ TopX
                \ :<C-U>exec "DBSelectFromTableTopX ".DB_getVisualBlock()<CR>
    noremenu <script> Plugin.dbext.Select\ Table\ Where
                \ :DBSelectFromTableWithWhere<CR>
    inoremenu <script> Plugin.dbext.Select\ Table\ Where
                \ <C-O>:DBSelectFromTableWithWhere<CR>
    noremenu <script> Plugin.dbext.Select\ Table\ Ask
                \ :DBSelectFromTableAskName<CR>
    inoremenu <script> Plugin.dbext.Select\ Table\ Ask
                \ <C-O>:DBSelectFromTableAskName<CR>
    noremenu <script> Plugin.dbext.Describe\ Table
                \ :DBDescribeTable<CR>
    inoremenu <script> Plugin.dbext.Describe\ Table
                \ <C-O>:DBDescribeTable<CR>
    vnoremenu <script> Plugin.dbext.Describe\ Table
                \ :<C-U>exec "DBDescribeTable ".DB_getVisualBlock()<CR>
    noremenu <script> Plugin.dbext.Describe\ Table\ Ask
                \ :DBDescribeTableAskName<CR>
    inoremenu <script> Plugin.dbext.Describe\ Table\ Ask
                \ <C-O>:DBDescribeTableAskName<CR>
    noremenu <script> Plugin.dbext.Describe\ Procedure
                \ :DBDescribeProcedure<CR>
    inoremenu <script> Plugin.dbext.Describe\ Procedure
                \ <C-O>:DBDescribeProcedure<CR>
    vnoremenu <script> Plugin.dbext.Describe\ Procedure
                \ :<C-U>exec "DBDescribeProcedure ".DB_getVisualBlock()<CR>
    noremenu <script> Plugin.dbext.Describe\ Procedure\ Ask
                \ :DBDescribeProcedureAskName<CR>
    inoremenu <script> Plugin.dbext.Describe\ Procedure\ Ask
                \ <C-O>:DBDescribeProcedureAskName<CR>
    noremenu <script> Plugin.dbext.Prompt\ Connect\ Info
                \ :DBPromptForBufferParameters<CR>
    noremenu <script> Plugin.dbext.Column\ List
                \ :DBListColumn<CR>
    inoremenu <script> Plugin.dbext.Column\ List
                \ <C-O>:DBListColumn<CR>
    vnoremenu <script> Plugin.dbext.Column\ List
                \ :<C-U>exec "DBListColumn ".DB_getVisualBlock()<CR>
    noremenu <script> Plugin.dbext.Table\ List
                \ :DBListTable<CR>
    inoremenu <script> Plugin.dbext.Table\ List
                \ <C-O>:DBListTable<CR>
    noremenu <script> Plugin.dbext.Procedure\ List
                \ :DBListProcedure<CR>
    inoremenu <script> Plugin.dbext.Procedure\ List
                \ <C-O>:DBListProcedure<CR>
    noremenu <script> Plugin.dbext.View\ List
                \ :DBListView<CR>
    inoremenu <script> Plugin.dbext.View\ List
                \ <C-O>:DBListView<CR>
    noremenu  <script> Plugin.dbext.Complete\ Tables  
                \ :DBCompleteTables<CR>
    noremenu  <script> Plugin.dbext.Complete\ Procedures  
                \ :DBCompleteProcedures<CR>
    noremenu  <script> Plugin.dbext.Complete\ Views  
                \ :DBCompleteViews<CR>
    noremenu  <script> Plugin.dbext.List\ Connections
                \ :DBListConnections<CR>
endif
"}}}
function! s:DB_checkModeline()
    " Users can preset connection string options using Vim's modeline 
    " features.
    " For example, in a SQL file you could have the following:
    "      -- dbext:profile=ASA_generic,user=bob
    " See the Help for more details.
    let rc = -1
    if ((&modeline == '0') || (&modelines < 1))
        return rc
    endif
    let saveSearch = @/
    let pattern = 'dbext:'
    let from_bottom_line = ((&modelines > line('$'))?1:(line('$')-&modelines))

    let savePos = 'normal! '.line(".").'G'.col(".")."\<bar>"
    silent execute "normal! 1G0\<bar>"
    while search( pattern, 'W' )
        if( (line(".") >= 1 && line(".") <= &modelines) ||
                    \ (line(".") >= from_bottom_line)   )
            call dbext#DB_checkModeline()
        endif
    endwhile

    let @/ = saveSearch
    execute savePos
    return rc
endfunction

function! DB_getDictionaryName( which ) 
    return dbext#DB_getDictionaryName( a:which )
endfunction 
function! DB_DictionaryCreate( drop_dict, which ) 
   return dbext#DB_DictionaryCreate( a:drop_dict, a:which ) 
endfunction

function! DB_listOption(...) 
    if a:0 == 0
        return dbext#DB_listOption() 
    elseif a:0 == 1
        return dbext#DB_listOption(a:1) 
    endif
endfunction

function! DB_getListColumn(...) 
    if(a:0 > 0) 
        " Strip any leading or trailing spaces
        let table_name = substitute(a:1, '\s*\(\S\+\).*', '\1', '')
    else
        let table_name = expand("<cword>")
    endif

    if(a:0 > 1) 
        " Suppress messages to the user, this prevents a echo
        " vim bug that offsets the output
        let silent_mode = a:2
    else
        let silent_mode = 0
    endif

    if(a:0 > 2) 
        " Separate with newlines
        let use_newline_sep = a:3
    else
        let use_newline_sep = 0
    endif

    return dbext#DB_getListColumn(table_name, silent_mode, use_newline_sep)
endfunction

function! DB_getVisualBlock() range
    let save = @"
    silent normal gvy
    let vis_cmd = @"
    let @" = save
    return vis_cmd
endfunction 

"" Get buffer parameter value
function! DB_execCmd(name, ...)

    let l:prev_use_result_buffer = DB_listOption('use_result_buffer')
    call dbext#DB_setMultipleOptions('use_result_buffer=0')
    " Could not figure out how to do this with an unlimited #
    " of variables, so I limited this to 4.  Currently we only use
    " 1 parameter in the code (May 2004), so that should be fine.
    " return dbext#DB_execFuncTypeWCheck('describeTable', table_name)
    if a:0 == 0
        let result = dbext#DB_execFuncWCheck(a:name)
    elseif a:0 == 1
        let result = dbext#DB_execFuncWCheck(a:name, a:1)
    elseif a:0 == 2
        let result = dbext#DB_execFuncWCheck(a:name, a:1, a:2)
    elseif a:0 == 3
        let result = dbext#DB_execFuncWCheck(a:name, a:1, a:2, a:3)
    else
        let result = dbext#DB_execFuncWCheck(a:name, a:1, a:2, a:3, a:4)
    endif
    call dbext#DB_setMultipleOptions('use_result_buffer='.l:prev_use_result_buffer)
    
    return result
endfunction

augroup dbext
    au!
    autocmd BufEnter    * if exists('g:loaded_dbext_auto') != 0 | exec "call dbext#DB_setTitle()" | endif
    autocmd BufReadPost * if &modeline == 1 | call s:DB_checkModeline() | endif
    autocmd BufDelete   * if exists('g:loaded_dbext_auto') != 0 | exec 'call dbext#DB_auBufDelete( expand("<abuf>") )' | endif
    autocmd VimLeavePre * if exists('g:loaded_dbext_auto') != 0 | exec 'call dbext#DB_auVimLeavePre()' | endif
augroup END

" vim:fdm=marker:nowrap:ts=4:expandtab:
