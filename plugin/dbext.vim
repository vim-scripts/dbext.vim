" dbext.vim - Commn Database Utility
" Copyright (C) 2002-10, Peter Bagyinszki, David Fishburn
" ---------------------------------------------------------------
" Version:       15.00
" Maintainer:    David Fishburn <dfishburn dot vim at gmail dot com>
" Authors:       Peter Bagyinszki <petike1 at dpg dot hu>
"                David Fishburn <dfishburn dot vim at gmail dot com>
" Last Modified: 2012 Apr 05
" Based On:      sqlplus.vim (author: Jamis Buck)
" Created:       2002-05-24
" Homepage:      http://vim.sourceforge.net/script.php?script_id=356
" Contributors:  Joerg Schoppet <joerg dot schoppet at web dot de>
"                Hari Krishna Dara <hari_vim at yahoo dot com>
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

if exists('g:loaded_dbext')
    finish
endif
if v:version < 700
    echomsg "dbext: Version 4.00 or higher requires Vim7.  Version 3.50 can stil be used with Vim6."
    finish
endif
let g:loaded_dbext = 1500

" Turn on support for line continuations when creating the script
let s:cpo_save = &cpo
set cpo&vim

if !exists('g:dbext_default_menu_mode')
    let g:dbext_default_menu_mode = 3
endif

if !exists('g:dbext_rows_affected')
    let g:dbext_rows_affected = 0
endif

" Commands {{{
command! -nargs=+ DBExecSQL         :call dbext#DB_execSql(<q-args>)
command! -nargs=+ DBExecSQLTopX     :call dbext#DB_execSqlTopX(<q-args>)
command! -nargs=0 DBConnect         :call dbext#DB_connect()
command! -nargs=* DBDisconnect      :call dbext#DB_disconnect(<q-args>)
command! -nargs=* DBDisconnectAll   :call dbext#DB_disconnectAll()
command! -nargs=0 DBCommit          :call dbext#DB_commit()
command! -nargs=0 DBRollback        :call dbext#DB_rollback()
command! -nargs=0 DBListConnections :call dbext#DB_getListConnections()
command! -range -nargs=0 DBExecRangeSQL <line1>,<line2>call dbext#DB_execRangeSql()
command! -nargs=+ Call              :call dbext#DB_execSql("call " . <q-args>)
command! -nargs=+ -complete=customlist,dbext#DB_completeTables Select            :call dbext#DB_execSql("select " . <q-args>)
command! -nargs=+ -complete=customlist,dbext#DB_completeTables Update            :call dbext#DB_execSql("update " . <q-args>)
command! -nargs=+ -complete=customlist,dbext#DB_completeTables Insert            :call dbext#DB_execSql("insert " . <q-args>)
command! -nargs=+ -complete=customlist,dbext#DB_completeTables Delete            :call dbext#DB_execSql("delete " . <q-args>)
command! -nargs=+ -complete=customlist,dbext#DB_completeTables Drop              :call dbext#DB_execSql("drop " . <q-args>)
command! -nargs=+ -complete=customlist,dbext#DB_completeTables Alter             :call dbext#DB_execSql("alter " . <q-args>)
command! -nargs=+ Create            :call dbext#DB_execSql("create " . <q-args>)
command! -nargs=1 DBSetOption       :call dbext#DB_setMultipleOptions(<q-args>)
command! -nargs=? DBGetOption       :echo DB_listOption(<q-args>)
" command! -nargs=* -complete=customlist,dbext#DB_completeSettings DBSetOption :call dbext#DB_setMultipleOptions(<q-args>)
command! -nargs=* -complete=customlist,dbext#DB_completeSettings DBSetOption :call dbext#DB_setMultipleOptions(<q-args>)
command! -nargs=* -complete=customlist,dbext#DB_completeSettings DBGetOption :echo DB_listOption(<q-args>)
command! -range -nargs=0 -bang DBVarRangeAssign <line1>,<line2>call dbext#DB_sqlVarRangeAssignment(<bang>0)
command! -nargs=0 DBListVar         :call dbext#DB_sqlVarList()
command! -nargs=1 -bang DBSetVar    :call dbext#DB_sqlVarAssignment(<bang>0, 'set '.<q-args>)
command! -nargs=* -complete=customlist,dbext#DB_completeVariable DBSetVar :call dbext#DB_sqlVarAssignment(<bang>0, 'set '.<q-args>)

if !exists(':DBExecVisualSQL')
    command! -nargs=0 -range DBExecVisualSQL :call dbext#DB_execSql(DB_getVisualBlock())
    xmap <unique> <script> <Plug>DBExecVisualSQL :DBExecVisualSQL<CR>
endif
if !exists(':DBExecVisualSQLTopX')
    command! -nargs=0 -range DBExecVisualSQLTopX :call dbext#DB_execSqlTopX(DB_getVisualBlock())
    xmap <unique> <script> <Plug>DBExecVisualTopXSQL :DBExecVisualSQLTopX<CR>
endif
if !exists(':DBExecSQLUnderCursor')
    command! -nargs=0 DBExecSQLUnderCursor
                \ :call dbext#DB_execSql(dbext#DB_getQueryUnderCursor())
    nmap <unique> <script> <Plug>DBExecSQLUnderCursor :DBExecSQLUnderCursor<CR>
endif
if !exists(':DBExecSQLUnderCursorTopX')
    command! -nargs=0 DBExecSQLUnderCursorTopX
                \ :call dbext#DB_execSqlTopX(dbext#DB_getQueryUnderCursor())
    nmap <unique> <script> <Plug>DBExecSQLUnderTopXCursor :DBExecSQLUnderCursorTopX<CR>
endif
if !exists(':DBExecSQL')
    command! -nargs=0 DBExecSQL
                \ :call dbext#DB_execSql(dbext#DB_parseQuery(dbext#DB_getQueryUnderCursor()))
    nmap <unique> <script> <Plug>DBExecSQL :DBExecSQL<CR>
endif
if !exists(':DBSelectFromTable')
    command! -nargs=* -range DBSelectFromTable
                \ :call dbext#DB_execSqlWithDefault("select * from ", <args>)
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
                \ :call dbext#DB_execSqlTopX(dbext#DB_getSqlWithDefault("select * from ", <args>))
    nmap <unique> <script> <Plug>DBSelectFromTopXTable :DBSelectFromTableTopX<CR>
endif
if !exists(':DBDescribeTable')
    command! -nargs=* -range DBDescribeTable
                \ :call dbext#DB_describeTable(<args>)
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
                \ :call dbext#DB_describeProcedure(<args>)
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
                \ :call DB_getListColumn(<args>)
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
if !exists(':DBResultsOpen')
    command! -nargs=0 DBResultsOpen
                \ :call dbext#DB_windowOpen()
end
if !exists(':DBResultsClose')
    command! -nargs=0 DBResultsClose
                \ :call dbext#DB_windowClose('')
end
if !exists(':DBResultsRefresh')
    command! -nargs=0 DBResultsRefresh
                \ :call dbext#DB_runPrevCmd()
end
if !exists(':DBResultsToggleResize')
    command! -nargs=0 DBResultsToggleResize
                \ :call dbext#DB_windowResize()
end
"}}}
" Mappings {{{
if !hasmapto('<Plug>DBExecVisualSQL') && !hasmapto('<Leader>se', 'v')
    xmap <unique> <Leader>se <Plug>DBExecVisualSQL
endif
if !hasmapto('<Plug>DBExecVisualTopXSQL') && !hasmapto('<Leader>sE', 'v')
    xmap <unique> <Leader>sE <Plug>DBExecVisualTopXSQL
endif
if !hasmapto('<Plug>DBExecSQLUnderCursor') && !hasmapto('<Leader>se', 'n')
    nmap <unique> <Leader>se <Plug>DBExecSQLUnderCursor
endif
if !hasmapto('<Plug>DBExecSQLUnderTopXCursor') && !hasmapto('<Leader>sE', 'n')
    nmap <unique> <Leader>sE <Plug>DBExecSQLUnderTopXCursor
endif
if !hasmapto('<Plug>DBExecSQL') && !hasmapto('<Leader>sq', 'n')
    nmap <unique> <Leader>sq <Plug>DBExecSQL
endif
if !hasmapto('DBExecRangeSQL')
    if !hasmapto('<Leader>sea', 'n')
        nmap <unique> <silent> <Leader>sea :1,$DBExecRangeSQL<CR>
    endif
    if !hasmapto('<Leader>sel', 'n')
        nmap <unique> <silent> <Leader>sel :.,.DBExecRangeSQL<CR>
    endif
    if !hasmapto('<Leader>sep', 'n')
        nmap <unique> <silent> <Leader>sep :'<,'>DBExecRangeSQL<CR>
    endif
endif
if !hasmapto('<Plug>DBSelectFromTable')
    if !hasmapto('<Leader>st', 'n')
        nmap <unique> <Leader>st <Plug>DBSelectFromTable
    endif
    if !hasmapto('<Leader>st', 'v')
        xmap <unique> <silent> <Leader>st
                    \ :<C-U>exec 'DBSelectFromTable "'.DB_getVisualBlock().'"'<CR>
    endif
endif
if !hasmapto('<Plug>DBSelectFromTableWithWhere') && !hasmapto('<Leader>stw', 'n')
    nmap <unique> <Leader>stw <Plug>DBSelectFromTableWithWhere
endif
if !hasmapto('<Plug>DBSelectFromTableAskName') && !hasmapto('<Leader>sta', 'n')
    nmap <unique> <Leader>sta <Plug>DBSelectFromTableAskName
endif
if !hasmapto('<Plug>DBSelectFromTopXTable') && !hasmapto('<Leader>sT')
    if !hasmapto('<Leader>sT', 'n')
        nmap <unique> <Leader>sT <Plug>DBSelectFromTopXTable
    endif
    if !hasmapto('<Leader>sT', 'v')
        xmap <unique> <silent> <Leader>sT
                    \ :<C-U>exec 'DBSelectFromTableTopX "'.DB_getVisualBlock().'"'<CR>
    endif
endif
if !hasmapto('<Plug>DBDescribeTable') && !hasmapto('<Leader>sdt')
    if !hasmapto('<Leader>sdt', 'n')
        nmap <unique> <Leader>sdt <Plug>DBDescribeTable
    endif
    if !hasmapto('<Leader>sdt', 'v')
        xmap <unique> <silent> <Leader>sdt
                    \ :<C-U>exec 'DBDescribeTable "'.DB_getVisualBlock().'"'<CR>
    endif
endif
if !hasmapto('<Plug>DBDescribeTableAskName') && !hasmapto('<Leader>sdta', 'n')
    nmap <unique> <Leader>sdta <Plug>DBDescribeTableAskName
endif
if !hasmapto('<Plug>DBDescribeProcedure') && !hasmapto('<Leader>sdp')
    if !hasmapto('<Leader>sdp', 'n')
        nmap <unique> <Leader>sdp <Plug>DBDescribeProcedure
    endif
    if !hasmapto('<Leader>sdp', 'v')
        xmap <unique> <silent> <Leader>sdp
                    \ :<C-U>exec 'DBDescribeProcedure "'.DB_getVisualBlock().'"'<CR>
    endif
endif
if !hasmapto('<Plug>DBDescribeProcedureAskName') && !hasmapto('<Leader>sdpa', 'n')
    nmap <unique> <Leader>sdpa <Plug>DBDescribeProcedureAskName
endif
if !hasmapto('<Plug>DBPromptForBufferParameters') && !hasmapto('<Leader>sbp', 'n')
    nmap <unique> <Leader>sbp <Plug>DBPromptForBufferParameters
endif
if !hasmapto('<Plug>DBListColumn') && !hasmapto('<Leader>slc')
    if !hasmapto('<Leader>slc', 'n')
        nmap <unique> <Leader>slc <Plug>DBListColumn
    endif
    if !hasmapto('<Leader>slc', 'v')
        xmap <unique> <silent> <Leader>slc
                    \ :<C-U>exec 'DBListColumn "'.DB_getVisualBlock().'"'<CR>
    endif
endif
if !hasmapto('<Plug>DBListTable') && !hasmapto('<Leader>slt', 'n')
    nmap <unique> <Leader>slt <Plug>DBListTable
endif
if !hasmapto('<Plug>DBListProcedure') && !hasmapto('<Leader>slp', 'n')
    nmap <unique> <Leader>slp <Plug>DBListProcedure
endif
if !hasmapto('<Plug>DBListView') && !hasmapto('<Leader>slv', 'n')
    nmap <unique> <Leader>slv <Plug>DBListView
endif
if !hasmapto('<Plug>DBListColumn') && !hasmapto('<Leader>stcl')
    if !hasmapto('<Leader>stcl', 'n')
        nmap <unique> <Leader>stcl <Plug>DBListColumn
    endif
    if !hasmapto('<Leader>stcl', 'v')
        xmap <unique> <silent> <Leader>stcl
                    \ :<C-U>exec 'DBListColumn "'.DB_getVisualBlock().'"'<CR>
    endif
endif
if !hasmapto('<Plug>DBHistory') && !hasmapto('<Leader>sh', 'n')
    nmap <unique> <Leader>sh <Plug>DBHistory
endif
if !hasmapto('<Plug>DBOrientationToggle') && !hasmapto('<Leader>so', 'n')
    nmap <unique> <Leader>so <Plug>DBOrientationToggle
endif
if !hasmapto('DBVarRangeAssign')
    if !hasmapto('<Leader>sas', 'n')
        nmap <unique> <silent> <Leader>sas :1,$DBVarRangeAssign<CR>
    endif
    if !hasmapto('<Leader>sal', 'n')
        nmap <unique> <silent> <Leader>sal :.,.DBVarRangeAssign<CR>
    endif
    if !hasmapto('<Leader>sap', 'n')
        nmap <unique> <silent> <Leader>sap :'<,'>DBVarRangeAssign<CR>
    endif
    if !hasmapto('<Leader>sa', 'v')
        xmap <unique> <silent> <Leader>sa :DBVarRangeAssign<CR>
    endif
endif
if !hasmapto('DBListVar')
    if !hasmapto('<Leader>slr', 'n')
        nmap <unique> <silent> <Leader>slr :DBListVar<CR>
    endif
endif
"}}}
" Menus {{{
if has("gui_running") && has("menu") && g:dbext_default_menu_mode != 0
    if g:dbext_default_menu_mode == 1
        let menuRoot = 'dbext'
    elseif g:dbext_default_menu_mode == 2
        let menuRoot = '&dbext'
    else
        let menuRoot = '&Plugin.&dbext'
    endif

    let leader = '\'
    if exists('g:mapleader')
        let leader = g:mapleader
    endif
    let leader = escape(leader, '\')

    exec 'vnoremenu <script> '.menuRoot.'.Execute\ SQL\ (Visual\ selection)<TAB>'.leader.'se :DBExecVisualSQL<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Execute\ SQL\ (Under\ cursor)<TAB>'.leader.'se  :DBExecSQLUnderCursor<CR>'
    exec 'vnoremenu <script> '.menuRoot.'.Execute\ SQL\ TopX\ (Visual\ selection)<TAB>'.leader.'sE  :DBExecVisualSQLTopX<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Execute\ SQL\ TopX\ (Under\ cursor)<TAB>'.leader.'sE  :DBExecSQLUnderCursorTopX<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Select\ Table<TAB>'.leader.'st  :DBSelectFromTable<CR>'
    exec 'inoremenu <script> '.menuRoot.'.Select\ Table<TAB>'.leader.'st  <C-O>:DBSelectFromTable<CR>'
    exec 'vnoremenu <script> '.menuRoot.'.Select\ Table<TAB>'.leader.'st  :<C-U>exec ''DBSelectFromTable "''.DB_getVisualBlock().''"''<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Select\ Table\ TopX<TAB>'.leader.'sT  :DBSelectFromTableTopX<CR>'
    exec 'inoremenu <script> '.menuRoot.'.Select\ Table\ TopX<TAB>'.leader.'sT  <C-O>:DBSelectFromTableTopX<CR>'
    exec 'vnoremenu <script> '.menuRoot.'.Select\ Table\ TopX<TAB>'.leader.'sT  :<C-U>exec ''DBSelectFromTableTopX "''.DB_getVisualBlock().''"''<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Select\ Table\ Where<TAB>'.leader.'stw  :DBSelectFromTableWithWhere<CR>'
    exec 'inoremenu <script> '.menuRoot.'.Select\ Table\ Where<TAB>'.leader.'stw  <C-O>:DBSelectFromTableWithWhere<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Select\ Table\ Ask<TAB>'.leader.'sta  :DBSelectFromTableAskName<CR>'
    exec 'inoremenu <script> '.menuRoot.'.Select\ Table\ Ask<TAB>'.leader.'sta  <C-O>:DBSelectFromTableAskName<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Describe\ Table<TAB>'.leader.'sdt  :DBDescribeTable<CR>'
    exec 'inoremenu <script> '.menuRoot.'.Describe\ Table<TAB>'.leader.'sdt  <C-O>:DBDescribeTable<CR>'
    exec 'vnoremenu <script> '.menuRoot.'.Describe\ Table<TAB>'.leader.'sdt  :<C-U>exec ''DBDescribeTable "''.DB_getVisualBlock().''"''<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Describe\ Table\ Ask<TAB>'.leader.'stda  :DBDescribeTableAskName<CR>'
    exec 'inoremenu <script> '.menuRoot.'.Describe\ Table\ Ask<TAB>'.leader.'stda  <C-O>:DBDescribeTableAskName<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Describe\ Procedure<TAB>'.leader.'sdp  :DBDescribeProcedure<CR>'
    exec 'inoremenu <script> '.menuRoot.'.Describe\ Procedure<TAB>'.leader.'sdp  <C-O>:DBDescribeProcedure<CR>'
    exec 'vnoremenu <script> '.menuRoot.'.Describe\ Procedure<TAB>'.leader.'sdp  :<C-U>exec ''DBDescribeProcedure "''.DB_getVisualBlock().''"''<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Describe\ Procedure\ Ask<TAB>'.leader.'sdpa  :DBDescribeProcedureAskName<CR>'
    exec 'inoremenu <script> '.menuRoot.'.Describe\ Procedure\ Ask<TAB>'.leader.'sdpa  <C-O>:DBDescribeProcedureAskName<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Prompt\ Connect\ Info<TAB>'.leader.'sbp  :DBPromptForBufferParameters<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Column\ List<TAB>'.leader.'slc  :DBListColumn<CR>'
    exec 'inoremenu <script> '.menuRoot.'.Column\ List<TAB>'.leader.'slc  <C-O>:DBListColumn<CR>'
    exec 'vnoremenu <script> '.menuRoot.'.Column\ List<TAB>'.leader.'slc  :<C-U>exec ''DBListColumn "''.DB_getVisualBlock().''"''<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Table\ List<TAB>'.leader.'slt  :DBListTable<CR>'
    exec 'inoremenu <script> '.menuRoot.'.Table\ List<TAB>'.leader.'slt  <C-O>:DBListTable<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Procedure\ List<TAB>'.leader.'slp  :DBListProcedure<CR>'
    exec 'inoremenu <script> '.menuRoot.'.Procedure\ List<TAB>'.leader.'slp  <C-O>:DBListProcedure<CR>'
    exec 'noremenu  <script> '.menuRoot.'.View\ List<TAB>'.leader.'slv  :DBListView<CR>'
    exec 'inoremenu <script> '.menuRoot.'.View\ List<TAB>'.leader.'slv  <C-O>:DBListView<CR>'
    exec 'vnoremenu <script> '.menuRoot.'.Assign\ Variable\ (Visual\ selection)<TAB>'.leader.'sa :DBVarRangeAssign<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Assign\ Variable\ (Current\ line)<TAB>'.leader.'sal :.,.DBVarRangeAssign<CR>'
    exec 'noremenu  <script> '.menuRoot.'.List\ Variables<TAB>'.leader.'slr :DBListVar<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Complete\ Tables :DBCompleteTables<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Complete\ Procedures :DBCompleteProcedures<CR>'
    exec 'noremenu  <script> '.menuRoot.'.Complete\ Views :DBCompleteViews<CR>'
    exec 'noremenu  <script> '.menuRoot.'.List\ Connections\ (DBI) :DBListConnections<CR>'
endif
"}}}
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
        let table_name = substitute(a:1, '\s*\(.\+\)\s*', '\1', '')
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
    " Mark the current line to return to
    let curline     = line("'>")
    let curcol      = virtcol("'>")

    silent normal gvy
    let vis_cmd = @"
    let @" = save

    " Return to previous location
    " Accounting for beginning of the line
    call cursor(curline, curcol)

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
    autocmd BufReadPost * if &modeline == 1 | call dbext#DB_checkModeline() | endif
    autocmd BufDelete   * if exists('g:loaded_dbext_auto') != 0 | exec 'call dbext#DB_auBufDelete( expand("<abuf>") )' | endif
    autocmd VimLeavePre * if exists('g:loaded_dbext_auto') != 0 | exec 'call dbext#DB_auVimLeavePre()' | endif
augroup END

let &cpo = s:cpo_save
unlet s:cpo_save

" vim:fdm=marker:nowrap:ts=4:expandtab:
