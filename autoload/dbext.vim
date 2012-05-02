" dbext.vim - Commn Database Utility
" Copyright (C) 2002-10, Peter Bagyinszki, David Fishburn
" ---------------------------------------------------------------
" Version:       15.00
" Maintainer:    David Fishburn <dfishburn dot vim at gmail dot com>
" Authors:       Peter Bagyinszki <petike1 at dpg dot hu>
"                David Fishburn <dfishburn dot vim at gmail dot com>
" Last Modified: 2012 Apr 30
" Based On:      sqlplus.vim (author: Jamis Buck)
" Created:       2002-05-24
" Homepage:      http://vim.sourceforge.net/script.php?script_id=356
" Contributors:  Joerg Schoppet 
"                Hari Krishna Dara 
"                Ron Aaron
"                Andi Stern
"                Sergey Khorev
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

if exists('g:loaded_dbext_auto') || &cp
    finish
endif
if v:version < 700
    echomsg "dbext: Version 4.00 or higher requires Vim7.  Version 3.50 can stil be used with Vim6."
    finish
endif
let g:loaded_dbext_auto = 1500

" Turn on support for line continuations when creating the script
let s:cpo_save = &cpo
set cpo&vim

" call confirm("Loaded dbext autoload", "&Ok")
" Script variable defaults, these are used internal and are never displayed
" to the end user via the DBGetOption command  {{{
" let s:dbext_buffers_with_dict_files = ''
let s:dbext_buffers_with_dict_files = []
" +shellslash is set on windows so it can be used to decide
" what type of slash to use
let s:dbext_tempfile = fnamemodify(tempname(), ":h").
            \ ((has('win32') && ! exists('+shellslash'))?'\':(has('vms')?'':'/')).
            \ 'dbext.sql'
let s:dbext_prev_sql     = ''
let s:dbext_result_count = 0
" Store previous buffer information so we can return to it when we 
" " Store previous buffer information so we can return to it when we 
" close the Result window
" close the Result window
let s:dbext_buffer_last_winnr = -1
let s:dbext_buffer_last       = -1
" }}}

" Build internal lists {{{
function! s:DB_buildLists()
    " Available DB types - maintainer in ()
    let s:db_types_mv = []
    " Sybase Adaptive Server Anywhere (fishburn)
    call add(s:db_types_mv, 'ASA')
    " Sybase Adaptive Server Enterprise (fishburn)
    call add(s:db_types_mv, 'ASE')
    " DB2 (fishburn)
    call add(s:db_types_mv, 'DB2')
    " Ingres (schoppet)
    call add(s:db_types_mv, 'INGRES')
    " Interbase (bagyinszki)
    call add(s:db_types_mv, 'INTERBASE')
    " MySQL (fishburn)
    call add(s:db_types_mv, 'MYSQL')
    " Oracle (fishburn)
    call add(s:db_types_mv, 'ORA')
    " PostgreSQL (fishburn)
    call add(s:db_types_mv, 'PGSQL')
    " Microsoft Sql Server (fishburn)
    call add(s:db_types_mv, 'SQLSRV')
    " SQLite (fishburn)
    call add(s:db_types_mv, 'SQLITE')
    " Oracle Rdb (stern)
    call add(s:db_types_mv, 'RDB')
    " Sybase SQL Anywhere UltraLite (fishburn)
    call add(s:db_types_mv, 'ULTRALITE')
    " Firebird (fishburn)
    call add(s:db_types_mv, 'FIREBIRD')

    " The following are only available with the
    " Perl DBI extension plug.
    " It requires a Perl enabled Vim  (ie echo has('perl')  )
    " Perl DBI (fishburn)
    call add(s:db_types_mv, 'DBI')
    " Perl DBI::ODBC (fishburn)
    call add(s:db_types_mv, 'ODBC')

    " Integrated Login Supported DB types
    let s:intlogin_types_mv = []
    "sybase adaptive server anywhere (fishburn)
    call add(s:intlogin_types_mv, 'ASA')
    "microsoft sql server (fishburn)
    call add(s:intlogin_types_mv, 'SQLSRV')

    " Connection parameters
    let s:conn_params_mv = []
    call add(s:conn_params_mv, 'profile')
    call add(s:conn_params_mv, 'type')
    call add(s:conn_params_mv, 'integratedlogin')
    call add(s:conn_params_mv, 'user')
    call add(s:conn_params_mv, 'passwd')
    call add(s:conn_params_mv, 'dsnname')
    call add(s:conn_params_mv, 'srvname')
    call add(s:conn_params_mv, 'dbname')
    call add(s:conn_params_mv, 'host')
    call add(s:conn_params_mv, 'port')
    call add(s:conn_params_mv, 'extra')
    call add(s:conn_params_mv, 'bin_path')
    call add(s:conn_params_mv, 'login_script')
    call add(s:conn_params_mv, 'driver')
    call add(s:conn_params_mv, 'conn_parms')
    call add(s:conn_params_mv, 'driver_parms')

    " Saved connection parameters
    let s:saved_conn_params_mv = []
    call add(s:saved_conn_params_mv, 'saved_profile')
    call add(s:saved_conn_params_mv, 'saved_type')
    call add(s:saved_conn_params_mv, 'saved_integratedlogin')
    call add(s:saved_conn_params_mv, 'saved_user')
    call add(s:saved_conn_params_mv, 'saved_passwd')
    call add(s:saved_conn_params_mv, 'saved_dsnname')
    call add(s:saved_conn_params_mv, 'saved_srvname')
    call add(s:saved_conn_params_mv, 'saved_dbname')
    call add(s:saved_conn_params_mv, 'saved_host')
    call add(s:saved_conn_params_mv, 'saved_port')
    call add(s:saved_conn_params_mv, 'saved_extra')
    call add(s:saved_conn_params_mv, 'saved_bin_path')
    call add(s:saved_conn_params_mv, 'saved_login_script')
    call add(s:saved_conn_params_mv, 'saved_driver')
    call add(s:saved_conn_params_mv, 'saved_conn_parms')
    call add(s:saved_conn_params_mv, 'saved_driver_parms')

    " Configuration parameters
    let s:config_params_mv = []
    call add(s:config_params_mv, 'use_sep_result_buffer')
    call add(s:config_params_mv, 'query_statements')
    call add(s:config_params_mv, 'parse_statements')
    call add(s:config_params_mv, 'prompt_for_parameters')
    call add(s:config_params_mv, 'prompting_user')
    call add(s:config_params_mv, 'always_prompt_for_variables')
    call add(s:config_params_mv, 'stop_prompt_for_variables')
    call add(s:config_params_mv, 'use_saved_variables')
    call add(s:config_params_mv, 'display_cmd_line')
    call add(s:config_params_mv, 'variable_def')
    call add(s:config_params_mv, 'variable_def_regex')
    call add(s:config_params_mv, 'buffer_defaulted')
    call add(s:config_params_mv, 'dict_show_owner')
    call add(s:config_params_mv, 'dict_table_file')
    call add(s:config_params_mv, 'dict_procedure_file')
    call add(s:config_params_mv, 'dict_view_file')
    call add(s:config_params_mv, 'replace_title')
    call add(s:config_params_mv, 'custom_title')
    call add(s:config_params_mv, 'use_tbl_alias')
    call add(s:config_params_mv, 'delete_temp_file')
    call add(s:config_params_mv, 'autoclose')
    call add(s:config_params_mv, 'autoclose_min_lines')
    call add(s:config_params_mv, 'variable_remember')
    call add(s:config_params_mv, 'filetype')

    " Script parameters
    let s:script_params_mv = []
    call add(s:script_params_mv, 'use_result_buffer')
    call add(s:script_params_mv, 'buffer_lines')
    call add(s:script_params_mv, 'result_bufnr')
    call add(s:script_params_mv, 'history_bufnr')
    call add(s:script_params_mv, 'history_file')
    call add(s:script_params_mv, 'history_size')
    call add(s:script_params_mv, 'history_max_entry')
    call add(s:script_params_mv, 'dbext_version')
    call add(s:script_params_mv, 'inputdialog_cancel_support')
    call add(s:script_params_mv, 'buffers_with_dict_files')
    call add(s:script_params_mv, 'use_win32_filenames')
    call add(s:script_params_mv, 'temp_file')
    call add(s:script_params_mv, 'window_use_horiz')
    call add(s:script_params_mv, 'window_use_bottom')
    call add(s:script_params_mv, 'window_use_right')
    call add(s:script_params_mv, 'window_width')
    call add(s:script_params_mv, 'window_increment')
    call add(s:script_params_mv, 'login_script_dir')

    " DB server specific params
    " See below for 3 additional DB2 items
    let s:db_params_mv = []
    call add(s:db_params_mv, 'bin')
    call add(s:db_params_mv, 'cmd_header')
    call add(s:db_params_mv, 'cmd_terminator')
    call add(s:db_params_mv, 'cmd_options')
    call add(s:db_params_mv, 'on_error')

    " DBI configuration parameters
    let s:config_dbi_mv = []
    call add(s:config_dbi_mv, 'DBI_max_rows')
    call add(s:config_dbi_mv, 'DBI_disconnect_onerror')
    call add(s:config_dbi_mv, 'DBI_commit_on_disconnect')
    call add(s:config_dbi_mv, 'DBI_split_on_pattern')
    call add(s:config_dbi_mv, 'DBI_read_file_cmd')
    call add(s:config_dbi_mv, 'DBI_cmd_terminator')
    call add(s:config_dbi_mv, 'DBI_orientation')
    call add(s:config_dbi_mv, 'DBI_column_delimiter')

    " DBI connection attributes
    let s:db_dbi_mv = []
    call add(s:db_dbi_mv, 'AutoCommit')
    call add(s:db_dbi_mv, 'PrintError')
    call add(s:db_dbi_mv, 'PrintWarn')
    call add(s:db_dbi_mv, 'RaiseError')
    call add(s:db_dbi_mv, 'Name')
    call add(s:db_dbi_mv, 'Statement')
    call add(s:db_dbi_mv, 'RowCacheSize')
    call add(s:db_dbi_mv, 'Username')
    call add(s:db_dbi_mv, 'Warn')
    call add(s:db_dbi_mv, 'Active')
    call add(s:db_dbi_mv, 'Executed')
    call add(s:db_dbi_mv, 'Kids')
    call add(s:db_dbi_mv, 'ActiveKids')
    call add(s:db_dbi_mv, 'CachedKids')
    call add(s:db_dbi_mv, 'Type')
    call add(s:db_dbi_mv, 'ChildHandles')
    call add(s:db_dbi_mv, 'CompatMode')
    call add(s:db_dbi_mv, 'InactiveDestroy')
    call add(s:db_dbi_mv, 'HandleError')
    call add(s:db_dbi_mv, 'HandleSetError')
    call add(s:db_dbi_mv, 'ErrCount')
    call add(s:db_dbi_mv, 'ShowErrorStatement')
    call add(s:db_dbi_mv, 'TraceLevel')
    call add(s:db_dbi_mv, 'FetchHashKeyName')
    call add(s:db_dbi_mv, 'ChopBlanks')
    call add(s:db_dbi_mv, 'LongReadLen')
    call add(s:db_dbi_mv, 'LongTruncOk')
    call add(s:db_dbi_mv, 'TaintIn')
    call add(s:db_dbi_mv, 'TaintOut')
    call add(s:db_dbi_mv, 'Taint')
    call add(s:db_dbi_mv, 'Profile')

    " All parameters
    let s:all_params_mv = []
    call extend(s:all_params_mv, s:conn_params_mv)
    call extend(s:all_params_mv, s:config_params_mv)
    call extend(s:all_params_mv, s:script_params_mv)

    let loop_count         = 0
    let s:prompt_type_list = "\n0. None"

    for type_mv in s:db_types_mv
        let loop_count = loop_count + 1
        let s:prompt_type_list = s:prompt_type_list . "\n" . loop_count . '. ' . type_mv 
        for param_mv in s:db_params_mv
            call add(s:all_params_mv, type_mv.'_'.param_mv)
        endfor
    endfor

    " Add 3 additional DB2 special cases
    call add(s:all_params_mv, 'DB2_use_db2batch')
    call add(s:all_params_mv, 'DB2_db2cmd_bin')
    call add(s:all_params_mv, 'DB2_db2cmd_cmd_options')

    " Add 1 additional MySQL special cases
    call add(s:all_params_mv, 'MYSQL_version')


    " Any predefined global connection profiles in the users vimrc
    let s:conn_profiles_mv    = []
    let loop_count            = 1
    let s:prompt_profile_list = "0. None"


    " Check if the user has any profiles defined in his vimrc
    redir => vars
    silent! let g:
    redir END
    let varlist = split(vars, '\n')
    call map(varlist, 'matchstr(v:val, ''^\S\+'')')
    call filter(varlist, 'v:val =~ ''^dbext_default_profile_''')

	for item in varlist
        let prof_name = matchstr(item, 'dbext_default_profile_\zs\(\w\+\)')
        if strlen(prof_name) > 0
            call add(s:conn_profiles_mv, prof_name)
        endif
	endfor
    " Sort the list ignoring CaSe
    let s:conn_profiles_mv = sort(s:conn_profiles_mv,1)
    " Build the profile prompt string
	for item in s:conn_profiles_mv
            let s:prompt_profile_list = s:prompt_profile_list . "\n" .
                        \  loop_count . '. ' . item
            let loop_count += 1
	endfor

    " Check if we are using Cygwin, if so, let the user override
    " the temporary filename to use backslashes
    if has('win32unix') && s:DB_get('use_win32_filenames') == 1
        let l:dbext_tempfile = system('cygpath -w '.s:dbext_tempfile)
        if v:shell_error 
            call s:DB_warningMsg('dbext:Failed to convert Cygwin path:'.v:errmsg)
        else
            " If executing the Windows path inside a Cygwin shell, you must
            " double up the backslashes
            let s:dbext_tempfile = substitute(l:dbext_tempfile, '\\', '\\\\', 'g')
        endif
        " let s:dbext_tempfile = substitute(s:dbext_tempfile, '/', '\', 'g')
    endif
endfunction 
"}}}

" Configuration {{{
"" Execute function, but prompt for parameters if necessary
function! dbext#DB_execFuncWCheck(name,...)
    " Record current buffer to return to the correct one
    let s:dbext_prev_winnr = winnr()
    let s:dbext_prev_bufnr = bufnr('%')
 
    let use_defaults = 1
    if s:DB_get("buffer_defaulted") != 1
        let rc = s:DB_resetBufferParameters(use_defaults)
        if rc == -1
            call s:DB_warningMsg( "dbext:A valid database type must be chosen" )
            return -1
        endif
        if a:name == 'promptForParameters'
            " Handle the special case where no parameters were defaulted
            " but the process of resettting them has defaulted them.
            call s:DB_warningMsg( "dbext:Connection parameters have been defaulted" )
        endif
    endif

    if exists('*s:DB_'.a:name) == 0
        call s:DB_warningMsg( "dbext:Function DB_".a:name." does not exist" )
        return "-1"
    endif

    echon 'dbext: Executing SQL at '.strftime("%H:%M")

    " Could not figure out how to do this with an unlimited #
    " of variables, so I limited this to 4.  Currently we only use
    " 1 parameter in the code (May 2004), so that should be fine.
    if a:0 == 0
        return s:DB_{a:name}()
    elseif a:0 == 1
        return s:DB_{a:name}(a:1)
    elseif a:0 == 2
        return s:DB_{a:name}(a:1, a:2)
    elseif a:0 == 3
        return s:DB_{a:name}(a:1, a:2, a:3)
    else
        return s:DB_{a:name}(a:1, a:2, a:3, a:4)
    endif
endfunction

"" Execute function, but prompt for parameters if necessary
function! dbext#DB_execFuncTypeWCheck(name,...)

    " Record current buffer to return to the correct one
    let s:dbext_prev_winnr = winnr()
    let s:dbext_prev_bufnr = bufnr('%')
 
    let use_defaults = 1
    if s:DB_get("buffer_defaulted") != 1
        let rc = s:DB_resetBufferParameters(use_defaults)
        if rc == -1
            call s:DB_warningMsg( "dbext:A valid database type must be chosen" )
            return rc
        endif
    endif

    if !exists("*s:DB_".b:dbext_type."_".a:name)
        let value = toupper(b:dbext_type)
        if index(s:db_types_mv, value) == -1
            call s:DB_warningMsg("dbext:Unknown database type: " . b:dbext_type)
            return ""
        else
            call s:DB_warningMsg( "dbext:s:DB_" . b:dbext_type .
                        \ '_' . a:name . 
                        \ ' not found'
                        \ )
            return ""
        endif
    endif

    echon 'dbext: Executing SQL at '.strftime("%H:%M")

    " Could not figure out how to do this with an unlimited #
    " of variables, so I limited this to 4.  Currently we only use
    " 1 parameter in the code (May 2004), so that should be fine.
    if a:0 == 0
        return s:DB_{b:dbext_type}_{a:name}()
    elseif a:0 == 1
        return s:DB_{b:dbext_type}_{a:name}(a:1)
    elseif a:0 == 2
        return s:DB_{b:dbext_type}_{a:name}(a:1, a:2)
    elseif a:0 == 3
        return s:DB_{b:dbext_type}_{a:name}(a:1, a:2, a:3)
    else
        return s:DB_{b:dbext_type}_{a:name}(a:1, a:2, a:3, a:4)
    endif
endfunction

function! s:DB_getTblAlias(table_name) 
    let owner      = s:DB_getObjectOwner(a:table_name)
    let table_name = s:DB_getObjectName(a:table_name)
    let tbl_alias = ''
    if s:DB_get("use_tbl_alias") != 'n'

        if 'da' =~? s:DB_get("use_tbl_alias")
            if table_name =~ '_'
                " Treat _ as separators since people often use these
                " for word separators
                let save_keyword = &iskeyword
                setlocal iskeyword-=_

                " Get the first letter of each word
                " [[:alpha:]] is used instead of \w 
                " to catch extended accented characters
                "
                let initials = substitute( 
                            \ table_name, 
                            \ '\<[[:alpha:]]\+\>_\?', 
                            \ '\=strpart(submatch(0), 0, 1)', 
                            \ 'g'
                            \ )
                " Restore original value
                let &iskeyword = save_keyword
            elseif table_name =~ '\u\U'
                let initials = substitute(
                            \ table_name, '\(\u\)\U*', '\1', 'g')
            else
                let initials = strpart(table_name, 0, 1)
            endif

            if 'a' =~? s:DB_get("use_tbl_alias")
                let tbl_alias = inputdialog("Enter table alias:", initials)
            else
                let tbl_alias = initials
            endif
        endif
        " Following a word character, make sure there is a . and no spaces
        let tbl_alias = substitute(tbl_alias, '\w\zs\.\?\s*$', '.', '')
    endif

    return tbl_alias
endfunction 

function! s:DB_getTitle() 
    let no_defaults  = 0
    let buffer_title = 0

    if s:DB_get("custom_title") == ''
        let buffer_title = '' .
                    \ s:DB_option('T(', s:DB_get("type"),          ')  ') .
                    \ s:DB_option('H(', s:DB_get("host"),          ')  ') .
                    \ s:DB_option('P(', s:DB_get("port"),          ')  ') .
                    \ s:DB_option('S(', s:DB_get("srvname"),       ')  ') .
                    \ s:DB_option('O(', s:DB_get("dsnname"),       ')  ') .
                    \ s:DB_option('D(', s:DB_get("dbname"),        ')  ') .
                    \ s:DB_option('I(', s:DB_get("driver"),        ')  ') .
                    \ s:DB_option('C(', s:DB_get("conn_parms"),    ')  ') .
                    \ s:DB_option('P(', s:DB_get("driver_parms"),  ')  ')

        if s:DB_get("integratedlogin") == '1'
            if has("win32")
                let buffer_title = buffer_title . 
                            \ s:DB_option('U(', expand("$USERNAME"), ')  ') 
            else
                let buffer_title = buffer_title . 
                            \ s:DB_option('U(', expand("$USER"), ')  ') 
            endif
        else
            let buffer_title = buffer_title . 
                        \ s:DB_option('U(', s:DB_get("user"), ')  ')
        endif

    else
        let buffer_title = s:DB_get("custom_title")
    endif

    return buffer_title
endfunction 

function! dbext#DB_setTitle() 
    let no_defaults = 0

    " In order to parse a statement, we must know what database type
    " we are dealing with to choose the correct cmd_terminator
    if s:DB_get("buffer_defaulted") == 1
        if s:DB_get("replace_title") == 1 && s:DB_get("type", no_defaults) != ''
            let &titlestring = s:DB_getTitle()
        endif
    endif

endfunction 

"" Set buffer parameter value
function! s:DB_set(name, value)
    if index(s:all_params_mv, a:name) > -1
        let value = a:value

        " If a value of -1 is provided assume an error
        " somewhere an abort
        if value == -1 
            return -1
        endif

        " Handle some special cases
        if (a:name ==# "type")
            " Do not check if the type already exists since
            " performing this additional check prevents the type
            " from being set to "@askb", so the user would never 
            " be prompted for a value.
            let value = toupper(value)
        endif
        " Profile will have to be retrieved from your vimrc
        " and each option must be processed
        if a:name == 'profile'
            " Now set the connection parameters from the profile
            if s:DB_parseProfile(value) == -1
                return -1
            endif
        endif

        if index(s:script_params_mv, a:name) > -1
            let s:dbext_{a:name} = value
        else
            let b:dbext_{a:name} = value
        endif

        if s:DB_get("replace_title") == '1'
            call dbext#DB_setTitle()
        endif
    elseif index(s:config_dbi_mv, a:name) > -1
        if a:value."" == ""
            call s:DB_set(a:name, s:DB_getDefault(a:name))
        else
            let b:dbext_{a:name} = a:value
        endif
        if a:name == 'DBI_commit_on_disconnect'
            " Special case since this option must be set
            " both in the DBI layer and the dbext plugin
            call s:DB_DBI_setOption(a:name, a:value)
        endif
    elseif index(s:saved_conn_params_mv, a:name) > -1
        " Store these parameters as script variables
        " since only 1 should ever be active at a time
        let s:dbext_{a:name} = a:value
    else
        if index(s:db_dbi_mv, a:name) > -1
            let rc = 0
            if s:DB_get('type') =~ '\<DBI\>\|\<ODBC\>'
                let rc = s:DB_DBI_setOption(a:name, a:value)
            endif
            return rc
        endif

        call s:DB_warningMsg("dbext:Unknown parameter: " . a:name)
        return -1
    endif

    return 0
endfunction

"" Set global variable parameter value
function! s:DB_setGlobal(name, value)
    let g:dbext_default_{a:name} = a:value

    return 0
endfunction

"" Set buffer parameter value based on database type
function! s:DB_setWType(name, value)
    let var_name = b:dbext_type."_".a:name
    call s:DB_set(var_name, a:value )
endfunction

"" Escape any special characters
function! s:DB_escapeStr(value)
    " Any special characters must be escaped before they can be used in a
    " search string or on the command line
    let escaped_str = 
                \ substitute(
                \     substitute(
                \         escape(a:value, '\\/.*$^~[]'),
                \         "\n$", 
                \         "", ""
                \     ),
                \     "\n", '\\_[[:return:]]', "g"
                \ )
    return escaped_str
endfunction

"" Get buffer parameter value
function! dbext#DB_listOption(...)
    let use_defaults = 1

    " Use defaults as the default for this function
    if (a:0 > 0) && strlen(a:1) > 0
        return s:DB_get(a:1, use_defaults)
    endif

    " Record current buffer to return to the correct one
    let s:dbext_prev_winnr = winnr()
    let s:dbext_prev_bufnr = bufnr('%')

    let conn_params_cnt   = len(s:conn_params_mv)
    let config_params_cnt = len(s:config_params_mv)
    let script_params_cnt = len(s:script_params_mv)

    let option_cnt  = 1
    let option_list = 
                \ "------------------------\n" .
                \ "** Connection Options **\n" .
                \ "------------------------\n"
    for param_mv in s:all_params_mv
        if option_cnt == (conn_params_cnt + 1) 
            let option_list = option_list .
                        \ "---------------------------\n" .
                        \ "** Configuration Options **\n" .
                        \ "---------------------------\n"
        elseif option_cnt == (conn_params_cnt +
                    \ config_params_cnt + 1)  
            let option_list = option_list .
                        \ "--------------------------\n" .
                        \ "** Script Level Options **\n" .
                        \ "--------------------------\n"
        elseif option_cnt == (conn_params_cnt +
                    \ config_params_cnt +
                    \ script_params_cnt + 1)  
            let option_list = option_list .
                        \ "----------------------\n" .
                        \ "** Database Options **\n" .
                        \ "----------------------\n"
        endif
        let opt_name    = param_mv
        try
            let opt_value   = opt_name . ' = ' . s:DB_get(opt_name)
        catch
            call s:DB_errorMsg('Failed to get:'.opt_name)
        endtry
        let option_list = option_list . opt_value . "\n"
        let option_cnt  = option_cnt + 1
    endfor
     
    let option_list = option_list .
                \ "---------------------\n" .
                \ "** DBI / DBI::ODBC **\n" .
                \ "---------------------\n"
    for dbi_mv in s:config_dbi_mv
        let opt_name    = dbi_mv
        let opt_value   = opt_name . ' = ' . s:DB_get(opt_name)
        let option_list = option_list . opt_value . "\n"
        let option_cnt  = option_cnt + 1
    endfor
     
    let option_list = option_list .
                \ "--------------\n" .
                \ "** Profiles **\n" .
                \ "--------------\n"
    for profile_mv in s:conn_profiles_mv
        let opt_name    = profile_mv
        " let opt_value   = opt_name . ' = ' . s:DB_get(opt_name)
        let opt_value   = ''
        if exists('g:dbext_default_profile_'.opt_name)
            let opt_value = matchstr(g:dbext_default_profile_{opt_name}, 'type=\zs\w\+\ze\(:\|$\)')
        endif
        let option_list = option_list . opt_name . ' T(' . opt_value . ")\n"
    endfor
     
    let option_list = option_list .
                \ "-------------------------------\n" .
                \ "** Overrides (via the vimrc) **\n" .
                \ "-------------------------------\n"
    " Check if the user has any profiles defined in his vimrc
    let saveA = @a
    redir  @a
    silent! exec 'let'
    redir END
    let l:global_vars = @a
    let @a = saveA

    let dbext_default_prefix = 'dbext_default_\zs\(\w\+\)'
    let index = match(l:global_vars, dbext_default_prefix)
    while index > -1
        " Retrieve the name of option
        let opt_name = matchstr(l:global_vars, '\w\+', index)
        if strlen(opt_name) > 0
            let opt_value = matchstr(l:global_vars, '\s*\zs[^'."\<C-J>".']\+', 
                        \ (index + strlen(opt_name))  )
            if opt_name !~ 'profile_'
                let option_list = option_list . opt_name . ' = ' . opt_value . "\n"
            endif
        endif
        let index = index + strlen(opt_name)+ strlen(opt_value) + 1
        let index = match(l:global_vars, dbext_default_prefix, index)
    endwhile

    let option_list = option_list .
                \ "-------------------------------\n" .
                \ "** Vim Version Information   **\n" .
                \ "-------------------------------\n"
    " Check if the user has any profiles defined in his vimrc
    redir => vim_version_info
    silent! version
    redir END
    let option_list = option_list . vim_version_info . "\n"

    call s:DB_addToResultBuffer(option_list, "clear")

    return ""
endfunction

"" Get buffer parameter value
function! s:DB_get(name, ...)
    " Use defaults as the default for this function
    let use_defaults = ((a:0 > 0)?(a:1+0):1)
    let no_default   = 0

    " Most parameters are buffer specific
    let prefix = "b:dbext_"

    " These two Lists store the list of parameters
    " that are script wide
    if index(s:script_params_mv, a:name) > -1
        let prefix = "s:dbext_"
    endif
    if index(s:saved_conn_params_mv, a:name) > -1
        let prefix = "s:dbext_"
    endif

    if exists(prefix.a:name)
        try
            let retval = {prefix}{a:name} . '' "force string
        catch
            let retval = join({prefix}{a:name}, ',') . '' "force string
        endtry
    elseif use_defaults == 1
        let retval = s:DB_getDefault(a:name)
    else
        let retval = ''
    endif

    if exists("b:dbext_prompting_user") && b:dbext_prompting_user != 1
        if retval =~? "@ask"
            let retval = s:DB_promptForParameters(a:name)
        endif
    endif

    return retval
endfunction

"" Get buffer parameter value based on database type
function! dbext#DB_getWType(name)
    if exists("b:dbext_type")
        let retval = s:DB_get(b:dbext_type.'_'.a:name)
    else
        let retval = ""
    endif
    
    return retval
endfunction

"" Get buffer defaulting to the buffer set value 
"" or if empty use the database type default.
function! dbext#DB_getWTypeDefault(name)
    let retval = s:DB_get(a:name)

    if retval == "" && exists("b:dbext_type")
        let retval = s:DB_get(b:dbext_type.'_'.a:name)
    endif
    
    return retval
endfunction

"" Returns hardcoded defaults for parameters.
function! s:DB_getDefault(name)
    " Must use g:dbext_default_profile.'' so that it is expanded
    if     a:name ==# "profile"                 |return (exists("g:dbext_default_profile")?g:dbext_default_profile.'':'@askb') 
    elseif a:name ==# "type"                    |return (exists("g:dbext_default_type")?g:dbext_default_type.'':'@askb') 
    elseif a:name ==# "integratedlogin"         |return (exists("g:dbext_default_integratedlogin")?g:dbext_default_integratedlogin.'':'0') 
    elseif a:name ==# "user"                    |return (exists("g:dbext_default_user")?g:dbext_default_user.'':'@askb') 
    elseif a:name ==# "passwd"                  |return (exists("g:dbext_default_passwd")?g:dbext_default_passwd.'':'@askb') 
    elseif a:name ==# "dsnname"                 |return (exists("g:dbext_default_dsnname")?g:dbext_default_dsnname.'':'') 
    elseif a:name ==# "srvname"                 |return (exists("g:dbext_default_srvname")?g:dbext_default_srvname.'':'') 
    elseif a:name ==# "dbname"                  |return (exists("g:dbext_default_dbname")?g:dbext_default_dbname.'':'') 
    elseif a:name ==# "host"                    |return (exists("g:dbext_default_host")?g:dbext_default_host.'':'') 
    elseif a:name ==# "port"                    |return (exists("g:dbext_default_port")?g:dbext_default_port.'':'') 
    elseif a:name ==# "extra"                   |return (exists("g:dbext_default_port")?g:dbext_default_port.'':'') 
    elseif a:name ==# "bin_path"                |return (exists("g:dbext_default_bin_path")?g:dbext_default_bin_path.'':'') 
    elseif a:name ==# "driver"                  |return (exists("g:dbext_default_driver")?g:dbext_default_driver.'':'') 
    elseif a:name ==# "driver_parms"            |return (exists("g:dbext_default_driver_parms")?g:dbext_default_driver_parms.'':'') 
    elseif a:name ==# "conn_parms"              |return (exists("g:dbext_default_conn_parms")?g:dbext_default_conn_parms.'':'') 
    " ? - look for a question mark
    " w - MUST have word characters after it
    " W - CANNOT have any word characters after it
    " q - quotes do not matter
    " Q - CANNOT be surrounded in quotes
    " , - delimiter between options
    elseif a:name ==# "variable_def"            |return (exists("g:dbext_default_variable_def")?g:dbext_default_variable_def.'':'?WQ,@wq,:wq,$wq')
    elseif a:name ==# "variable_def_regex"      |return (exists("g:dbext_default_variable_def_regex")?g:dbext_default_variable_def_regex.'':'\(\w\|'."'".'\)\@<!?\(\w\|'."'".'\)\@<!,\zs\(@\|:\a\|$\)\w\+\>')
    elseif a:name ==# "buffer_lines"            |return (exists("g:dbext_default_buffer_lines")?g:dbext_default_buffer_lines.'':10)
    elseif a:name ==# "use_result_buffer"       |return (exists("g:dbext_default_use_result_buffer")?g:dbext_default_use_result_buffer.'':1)
    elseif a:name ==# "use_sep_result_buffer"   |return (exists("g:dbext_default_use_sep_result_buffer")?g:dbext_default_use_sep_result_buffer.'':0)
    elseif a:name ==# "display_cmd_line"        |return (exists("g:dbext_default_display_cmd_line")?g:dbext_default_display_cmd_line.'':0)
    elseif a:name ==# "prompt_for_parameters"   |return (exists("g:dbext_default_prompt_for_parameters")?g:dbext_default_prompt_for_parameters.'':1)
    elseif a:name ==# "query_statements"        |return (exists("g:dbext_default_query_statements")?g:dbext_default_query_statements.'':'select,update,delete,insert,create,grant,alter,call,exec,merge,with')
    elseif a:name ==# "parse_statements"        |return (exists("g:dbext_default_parse_statements")?g:dbext_default_parse_statements.'':'select,update,delete,insert,call,exec,with')
    elseif a:name ==# "always_prompt_for_variables" |return (exists("g:dbext_default_always_prompt_for_variables")?g:dbext_default_always_prompt_for_variables.'':0)
    elseif a:name ==# "replace_title"           |return (exists("g:dbext_default_replace_title")?g:dbext_default_replace_title.'':0)
    elseif a:name ==# "use_tbl_alias"           |return (exists("g:dbext_default_use_tbl_alias")?g:dbext_default_use_tbl_alias.'':'a')
    elseif a:name ==# "delete_temp_file"        |return (exists("g:dbext_default_delete_temp_file")?g:dbext_default_delete_temp_file.'':'1')
    elseif a:name ==# "buffers_with_dict_files" |return s:dbext_buffers_with_dict_files
    elseif a:name ==# "temp_file"               |return s:dbext_tempfile
    elseif a:name ==# "window_use_horiz"        |return (exists("g:dbext_default_window_use_horiz")?g:dbext_default_window_use_horiz.'':'1')
    elseif a:name ==# "window_width"            |return (exists("g:dbext_default_window_width")?g:dbext_default_window_width.'':'1')
    elseif a:name ==# "window_use_bottom"       |return (exists("g:dbext_default_window_use_bottom")?g:dbext_default_window_use_bottom.'':'1')
    elseif a:name ==# "window_use_right"        |return (exists("g:dbext_default_window_use_right")?g:dbext_default_window_use_right.'':'1')
    elseif a:name ==# "window_increment"        |return (exists("g:dbext_default_window_increment")?g:dbext_default_window_increment.'':'1')
    elseif a:name ==# "login_script_dir"        |return (exists("g:dbext_default_login_script_dir")?g:dbext_default_login_script_dir.'':'')
    elseif a:name ==# "use_win32_filenames"     |return (exists("g:dbext_default_use_win32_filenames")?g:dbext_default_use_win32_filenames.'':'0')
    elseif a:name ==# "dbext_version"           |return (g:loaded_dbext)
    elseif a:name ==# "history_file"            |return (exists("g:dbext_default_history_file")?g:dbext_default_history_file.'':(has('win32')?$VIM.'/dbext_sql_history.txt':$HOME.'/dbext_sql_history.txt'))
    elseif a:name ==# "history_bufname"         |return (fnamemodify(s:DB_get('history_file'), ":t:r"))
    elseif a:name ==# "history_size"            |return (exists("g:dbext_default_history_size")?g:dbext_default_history_size.'':'50')
    elseif a:name ==# "history_max_entry"       |return (exists("g:dbext_default_history_max_entry")?g:dbext_default_history_max_entry.'':'4096')
    elseif a:name ==# "autoclose"               |return (exists("g:dbext_default_autoclose")?g:dbext_default_autoclose.'':'0')
    elseif a:name ==# "autoclose_min_lines"     |return (exists("g:dbext_default_autoclose_min_lines")?g:dbext_default_autoclose_min_lines.'':'2')
    elseif a:name ==# "variable_remember"       |return (exists("g:dbext_default_variable_remember")?g:dbext_default_variable_remember.'':'1')
    elseif a:name ==# "ASA_bin"                 |return (exists("g:dbext_default_ASA_bin")?g:dbext_default_ASA_bin.'':'dbisql')
    elseif a:name ==# "ASA_cmd_terminator"      |return (exists("g:dbext_default_ASA_cmd_terminator")?g:dbext_default_ASA_cmd_terminator.'':';')
    elseif a:name ==# "ASA_cmd_options"         |return (exists("g:dbext_default_ASA_cmd_options")?g:dbext_default_ASA_cmd_options.'':'-nogui')
    elseif a:name ==# "ASA_on_error"            |return (exists("g:dbext_default_ASA_on_error")?g:dbext_default_ASA_on_error.'':'exit')
    elseif a:name ==# "ASA_SQL_Top_pat"         |return (exists("g:dbext_default_ASA_SQL_Top_pat")?g:dbext_default_ASA_SQL_Top_pat.'':'\(\cselect\)')
    elseif a:name ==# "ASA_SQL_Top_sub"         |return (exists("g:dbext_default_ASA_SQL_Top_sub")?g:dbext_default_ASA_SQL_Top_sub.'':'\1 TOP @dbext_topX ')
    elseif a:name ==# "ULTRALITE_bin"            |return (exists("g:dbext_default_ULTRALITE_bin")?g:dbext_default_ULTRALITE_bin.'':'dbisql')
    elseif a:name ==# "ULTRALITE_cmd_terminator" |return (exists("g:dbext_default_ULTRALITE_cmd_terminator")?g:dbext_default_ULTRALITE_cmd_terminator.'':';')
    elseif a:name ==# "ULTRALITE_cmd_options"    |return (exists("g:dbext_default_ULTRALITE_cmd_options")?g:dbext_default_ULTRALITE_cmd_options.'':'-nogui -ul')
    elseif a:name ==# "ULTRALITE_on_error"       |return (exists("g:dbext_default_ULTRALITE_on_error")?g:dbext_default_ULTRALITE_on_error.'':'exit')
    elseif a:name ==# "ULTRALITE_SQL_Top_pat"    |return (exists("g:dbext_default_ULTRALITE_SQL_Top_pat")?g:dbext_default_ULTRALITE_SQL_Top_pat.'':'\(\cselect\)')
    elseif a:name ==# "ULTRALITE_SQL_Top_sub"    |return (exists("g:dbext_default_ULTRALITE_SQL_Top_sub")?g:dbext_default_ULTRALITE_SQL_Top_sub.'':'\1 TOP @dbext_topX ')
    elseif a:name ==# "ASE_bin"                 |return (exists("g:dbext_default_ASE_bin")?g:dbext_default_ASE_bin.'':'isql')
    elseif a:name ==# "ASE_cmd_terminator"      |return (exists("g:dbext_default_ASE_cmd_terminator")?g:dbext_default_ASE_cmd_terminator.'':"\ngo\n")
    elseif a:name ==# "ASE_cmd_options"         |return (exists("g:dbext_default_ASE_cmd_options")?g:dbext_default_ASE_cmd_options.'':'-w 10000')
    elseif a:name ==# "ASE_SQL_Top_pat"         |return (exists("g:dbext_default_ASE_SQL_Top_pat")?g:dbext_default_ASE_SQL_Top_pat.'':'\(.*\)')
    elseif a:name ==# "ASE_SQL_Top_sub"         |return (exists("g:dbext_default_ASE_SQL_Top_sub")?g:dbext_default_ASE_SQL_Top_sub.'':'SET rowcount @dbext_topX \1')
    elseif a:name ==# "DB2_use_db2batch"        |return (exists("g:dbext_default_DB2_use_db2batch")?g:dbext_default_DB2_use_db2batch.'':(has('win32')?'0':'1'))
    elseif a:name ==# "DB2_bin"                 |return (exists("g:dbext_default_DB2_bin")?g:dbext_default_DB2_bin.'':'db2batch')
    elseif a:name ==# "DB2_cmd_options"         |return (exists("g:dbext_default_DB2_cmd_options")?g:dbext_default_DB2_cmd_options.'':'-q off -s off')
    elseif a:name ==# "DB2_db2cmd_bin"          |return (exists("g:dbext_default_DB2_db2cmd_bin")?g:dbext_default_DB2_db2cmd_bin.'':'db2cmd')
    elseif a:name ==# "DB2_db2cmd_cmd_options"  |return (exists("g:dbext_default_DB2_db2cmd_cmd_options")?g:dbext_default_DB2_db2cmd_cmd_options.'':'-c -w -i -t db2 -s')
    elseif a:name ==# "DB2_cmd_terminator"      |return (exists("g:dbext_default_DB2_cmd_terminator")?g:dbext_default_DB2_cmd_terminator.'':';')
    elseif a:name ==# "DB2_SQL_Top_pat"         |return (exists("g:dbext_default_DB2_SQL_Top_pat")?g:dbext_default_DB2_SQL_Top_pat.'':'\(.*\)')
    elseif a:name ==# "DB2_SQL_Top_sub"         |return (exists("g:dbext_default_DB2_SQL_Top_sub")?g:dbext_default_DB2_SQL_Top_sub.'':'\1 FETCH FIRST @dbext_topX ROWS ONLY')
    elseif a:name ==# "INGRES_bin"              |return (exists("g:dbext_default_INGRES_bin")?g:dbext_default_INGRES_bin.'':'sql')
    elseif a:name ==# "INGRES_cmd_options"      |return (exists("g:dbext_default_INGRES_cmd_options")?g:dbext_default_INGRES_cmd_options.'':'')
    elseif a:name ==# "INGRES_cmd_terminator"   |return (exists("g:dbext_default_INGRES_cmd_terminator")?g:dbext_default_INGRES_cmd_terminator.'':'\p\g')
    elseif a:name ==# "INTERBASE_bin"           |return (exists("g:dbext_default_INTERBASE_bin")?g:dbext_default_INTERBASE_bin.'':'isql')
    elseif a:name ==# "INTERBASE_cmd_options"   |return (exists("g:dbext_default_INTERBASE_cmd_options")?g:dbext_default_INTERBASE_cmd_options.'':'')
    elseif a:name ==# "INTERBASE_cmd_terminator"|return (exists("g:dbext_default_INTERBASE_cmd_terminator")?g:dbext_default_INTERBASE_cmd_terminator.'':';')
    elseif a:name ==# "MYSQL_bin"               |return (exists("g:dbext_default_MYSQL_bin")?g:dbext_default_MYSQL_bin.'':'mysql')
    elseif a:name ==# "MYSQL_cmd_options"       |return (exists("g:dbext_default_MYSQL_cmd_options")?g:dbext_default_MYSQL_cmd_options.'':'')
    elseif a:name ==# "MYSQL_cmd_terminator"    |return (exists("g:dbext_default_MYSQL_cmd_terminator")?g:dbext_default_MYSQL_cmd_terminator.'':';')
    elseif a:name ==# "MYSQL_version"           |return (exists("g:dbext_default_MYSQL_version")?g:dbext_default_MYSQL_version.'':'5')
    elseif a:name ==# "MYSQL_extra"             |return (exists("g:dbext_default_MYSQL_extra")?g:dbext_default_MYSQL_extra.'':'-t')
    elseif a:name ==# "MYSQL_SQL_Top_pat"       |return (exists("g:dbext_default_MYSQL_SQL_Top_pat")?g:dbext_default_MYSQL_SQL_Top_pat.'':'\(.*\)')
    elseif a:name ==# "MYSQL_SQL_Top_sub"       |return (exists("g:dbext_default_MYSQL_SQL_Top_sub")?g:dbext_default_MYSQL_SQL_Top_sub.'':'\1 LIMIT @dbext_topX ')
    elseif a:name ==# "FIREBIRD_bin"            |return (exists("g:dbext_default_FIREBIRD_bin")?g:dbext_default_FIREBIRD_bin.'':'isql')
    elseif a:name ==# "FIREBIRD_cmd_options"    |return (exists("g:dbext_default_FIREBIRD_cmd_options")?g:dbext_default_FIREBIRD_cmd_options.'':'')
    elseif a:name ==# "FIREBIRD_cmd_terminator" |return (exists("g:dbext_default_FIREBIRD_cmd_terminator")?g:dbext_default_FIREBIRD_cmd_terminator.'':';')
    elseif a:name ==# "FIREBIRD_version"        |return (exists("g:dbext_default_FIREBIRD_version")?g:dbext_default_FIREBIRD_version.'':'5')
    elseif a:name ==# "FIREBIRD_SQL_Top_pat"    |return (exists("g:dbext_default_FIREBIRD_SQL_Top_pat")?g:dbext_default_FIREBIRD_SQL_Top_pat.'':'\(.*\)')
    elseif a:name ==# "FIREBIRD_SQL_Top_sub"    |return (exists("g:dbext_default_FIREBIRD_SQL_Top_sub")?g:dbext_default_FIREBIRD_SQL_Top_sub.'':'\1 FIRST @dbext_topX ')
    elseif a:name ==# "ORA_bin"                 |return (exists("g:dbext_default_ORA_bin")?g:dbext_default_ORA_bin.'':'sqlplus')
    elseif a:name ==# "ORA_cmd_header"          |return (exists("g:dbext_default_ORA_cmd_header")?g:dbext_default_ORA_cmd_header.'':"" .
                        \ "set pagesize 50000\n" .
                        \ "set wrap off\n" .
                        \ "set sqlprompt \"\"\n" .
                        \ "set linesize 10000\n" .
                        \ "set flush off\n" .
                        \ "set colsep \"   \"\n" .
                        \ "set tab off\n\n")
    elseif a:name ==# "ORA_cmd_options"         |return (exists("g:dbext_default_ORA_cmd_options")?g:dbext_default_ORA_cmd_options.'':"-S")
    elseif a:name ==# "ORA_cmd_terminator"      |return (exists("g:dbext_default_ORA_cmd_terminator")?g:dbext_default_ORA_cmd_terminator.'':";")
    elseif a:name ==# "ORA_SQL_Top_pat"         |return (exists("g:dbext_default_ORA_SQL_Top_pat")?g:dbext_default_ORA_SQL_Top_pat.'':'\(.*\)')
    elseif a:name ==# "ORA_SQL_Top_sub"         |return (exists("g:dbext_default_ORA_SQL_Top_sub")?g:dbext_default_ORA_SQL_Top_sub.'':'SELECT * FROM (\1) WHERE rownum <= @dbext_topX ')
    elseif a:name ==# "PGSQL_bin"               |return (exists("g:dbext_default_PGSQL_bin")?g:dbext_default_PGSQL_bin.'':'psql')
    elseif a:name ==# "PGSQL_cmd_options"       |return (exists("g:dbext_default_PGSQL_cmd_options")?g:dbext_default_PGSQL_cmd_options.'':'')
    elseif a:name ==# "PGSQL_cmd_terminator"    |return (exists("g:dbext_default_PGSQL_cmd_terminator")?g:dbext_default_PGSQL_cmd_terminator.'':';')
    elseif a:name ==# "PGSQL_SQL_Top_pat"       |return (exists("g:dbext_default_PGSQL_SQL_Top_pat")?g:dbext_default_PGSQL_SQL_Top_pat.'':'\(.*\)')
    elseif a:name ==# "PGSQL_SQL_Top_sub"       |return (exists("g:dbext_default_PGSQL_SQL_Top_sub")?g:dbext_default_PGSQL_SQL_Top_sub.'':'\1 LIMIT @dbext_topX ')
    elseif a:name ==# "PGSQL_pgpass"            |return (exists("g:dbext_default_PGSQL_pgpass")?g:dbext_default_PGSQL_pgpass.'':'$HOME/.pgpass')
    elseif a:name ==# "RDB_bin"                 |return (exists("g:dbext_default_RDB_bin")?g:dbext_default_RDB_bin.'':'mc sql$')
    elseif a:name ==# "RDB_cmd_header"          |return (exists("g:dbext_default_RDB_cmd_header")?g:dbext_default_RDB_cmd_header.'':"".
                \ "set line length 10000\n" .
                \ "set page length 10000\n")
    elseif a:name ==# "RDB_cmd_options"         |return (exists("g:dbext_default_RDB_cmd_options")?g:dbext_default_RDB_cmd_options.'':"")
    elseif a:name ==# "RDB_cmd_terminator"      |return (exists("g:dbext_default_RDB_cmd_terminator")?g:dbext_default_RDB_cmd_terminator.'':";\n")
    elseif a:name ==# "RDB_SQL_Top_pat"         |return (exists("g:dbext_default_RDB_SQL_Top_pat")?g:dbext_default_RDB_SQL_Top_pat.'':'\(.*\)')
    elseif a:name ==# "RDB_SQL_Top_sub"         |return (exists("g:dbext_default_RDB_SQL_Top_sub")?g:dbext_default_RDB_SQL_Top_sub.'':'\1 LIMIT to @dbext_topX rows ')
    elseif a:name ==# "SQLITE_bin"              |return (exists("g:dbext_default_SQLITE_bin")?g:dbext_default_SQLITE_bin.'':'sqlite')
    elseif a:name ==# "SQLITE_cmd_header"       |return (exists("g:dbext_default_SQLITE_cmd_header")?g:dbext_default_SQLITE_cmd_header.'':".mode column\n.headers ON\n")
    elseif a:name ==# "SQLITE_cmd_options"      |return (exists("g:dbext_default_SQLITE_cmd_options")?g:dbext_default_SQLITE_cmd_options.'':'')
    elseif a:name ==# "SQLITE_cmd_terminator"   |return (exists("g:dbext_default_SQLITE_cmd_terminator")?g:dbext_default_SQLITE_cmd_terminator.'':';')
    elseif a:name ==# "SQLSRV_bin"              |return (exists("g:dbext_default_SQLSRV_bin")?g:dbext_default_SQLSRV_bin.'':'osql')
    elseif a:name ==# "SQLSRV_cmd_options"      |return (exists("g:dbext_default_SQLSRV_cmd_options")?g:dbext_default_SQLSRV_cmd_options.'':'-w 10000 -r -b -n')
    elseif a:name ==# "SQLSRV_cmd_terminator"   |return (exists("g:dbext_default_SQLSRV_cmd_terminator")?g:dbext_default_SQLSRV_cmd_terminator.'':"\ngo\n")
    elseif a:name ==# "SQLSRV_SQL_Top_pat"      |return (exists("g:dbext_default_SQLSRV_SQL_Top_pat")?g:dbext_default_SQLSRV_SQL_Top_pat.'':'\(\cselect\)')
    elseif a:name ==# "SQLSRV_SQL_Top_sub"      |return (exists("g:dbext_default_SQLSRV_SQL_Top_sub")?g:dbext_default_SQLSRV_SQL_Top_sub.'':'\1 TOP @dbext_topX ')
    elseif a:name ==# "prompt_profile"          |return (exists("g:dbext_default_prompt_profile")?g:dbext_default_prompt_profile.'':"" .
                \ (has('gui_running')?("[Optional] Enter profile #:\n".s:prompt_profile_list):
                \ (s:prompt_profile_list."\n[Optional] Enter profile #: "))
                \ )
    elseif a:name ==# "prompt_type"             |return (exists("g:dbext_default_prompt_type")?g:dbext_default_prompt_type.'':"" .
                \ (has('gui_running')?("\nDatabase:".s:prompt_type_list):
                \ (s:prompt_type_list."\nDatabase: "))
                \ )
    elseif a:name ==# "prompt_integratedlogin"  |return (exists("g:dbext_default_prompt_integratedlogin")?g:dbext_default_prompt_integratedlogin.'':'[Optional] Use Integrated Login: ')
    elseif a:name ==# "prompt_user"             |return (exists("g:dbext_default_prompt_user")?g:dbext_default_prompt_user.'':'[Optional] Database user: ')
    elseif a:name ==# "prompt_passwd"           |return (exists("g:dbext_default_prompt_passwd")?g:dbext_default_prompt_passwd.'':'[O] User password: ')
    elseif a:name ==# "prompt_dsnname"          |return (exists("g:dbext_default_prompt_dsnname")?g:dbext_default_prompt_dsnname.'':'[O] ODBC DSN: ')
    elseif a:name ==# "prompt_srvname"          |return (exists("g:dbext_default_prompt_srvname")?g:dbext_default_prompt_srvname.'':'[O] Server name: ')
    elseif a:name ==# "prompt_dbname"           |return (exists("g:dbext_default_prompt_dbname")?g:dbext_default_prompt_dbname.'':'[O] Database name: ')
    elseif a:name ==# "prompt_host"             |return (exists("g:dbext_default_prompt_host")?g:dbext_default_prompt_host.'':'[O] Host name: ')
    elseif a:name ==# "prompt_port"             |return (exists("g:dbext_default_prompt_port")?g:dbext_default_prompt_port.'':'[O] Port name: ')
    elseif a:name ==# "prompt_extra"            |return (exists("g:dbext_default_prompt_extra")?g:dbext_default_prompt_extra.'':'[O] Extra parameters: ')
    elseif a:name ==# "prompt_bin_path"         |return (exists("g:dbext_default_prompt_bin_path")?g:dbext_default_prompt_bin_path.'':'[O] Directory for database tools: ')
    elseif a:name ==# "prompt_login_script"       |return (exists("g:dbext_default_prompt_login_script")?g:dbext_default_prompt_login_script.'':'[O] Login Script: ')
    elseif a:name ==# "prompt_driver"           |return (exists("g:dbext_default_prompt_driver")?g:dbext_default_prompt_driver.'':'[O] DBI driver: ')
    elseif a:name ==# "prompt_driver_parms"     |return (exists("g:dbext_default_prompt_driver_parms")?g:dbext_default_prompt_driver_parms.'':'[O] DBI driver parameters: ')
    elseif a:name ==# "prompt_conn_parms"       |return (exists("g:dbext_default_prompt_conn_parms")?g:dbext_default_prompt_conn_parms.'':'[O] DBI connection parameters: ')
    " These are for name completion using Vim's dictionary feature
    elseif a:name ==# "dict_show_owner"         |return (exists("g:dbext_default_dict_show_owner")?g:dbext_default_dict_show_owner.'':'1')
    elseif a:name ==# "dict_table_file"         |return '' 
    elseif a:name ==# "dict_procedure_file"     |return '' 
    elseif a:name ==# "dict_view_file"          |return ''
    elseif a:name ==# "inputdialog_cancel_support"       |return (exists("g:dbext_default_inputdialog_cancel_support")?g:dbext_default_inputdialog_cancel_support.'':((v:version>=602)?'1':'0'))
    " DBI Settings
    elseif a:name ==# "DBI_max_rows"             |return (exists("g:dbext_default_DBI_max_rows")?g:dbext_default_DBI_max_rows.'':'300')
    elseif a:name ==# "DBI_disconnect_onerror"   |return (exists("g:dbext_default_DBI_disconnect_onerror")?g:dbext_default_DBI_disconnect_onerror.'':'1')
    elseif a:name ==# "DBI_commit_on_disconnect" |return (exists("g:dbext_default_DBI_commit_on_disconnect")?g:dbext_default_DBI_commit_on_disconnect.'':'1')
    elseif a:name ==# "DBI_split_on_pattern"     |return (exists("g:dbext_default_DBI_split_on_pattern")?g:dbext_default_DBI_split_on_pattern.'':"\n".'\s*\<go\>\s*'."\n")
    elseif a:name ==# "DBI_read_file_cmd"        |return (exists("g:dbext_default_DBI_read_file_cmd")?g:dbext_default_DBI_read_file_cmd.'':'read ')
    elseif a:name ==# "DBI_cmd_terminator"       |return (exists("g:dbext_default_DBI_cmd_terminator")?g:dbext_default_DBI_cmd_terminator.'':';')
    elseif a:name ==# "DBI_orientation"          |return (exists("g:dbext_default_DBI_orientation")?g:dbext_default_DBI_orientation.'':'horizontal')
    elseif a:name ==# "DBI_column_delimiter"     |return (exists("g:dbext_default_DBI_column_delimiter")?g:dbext_default_DBI_column_delimiter.'':"  ")
    elseif a:name ==# "DBI_table_type"           |return (exists("g:dbext_default_DBI_table_type")?g:dbext_default_DBI_table_type.'':'TABLE')
    elseif a:name ==# "DBI_view_type"            |return (exists("g:dbext_default_DBI_view_type")?g:dbext_default_DBI_view_type.'':'VIEW')
    elseif a:name ==# "DBI_trace_level"          |return (exists("g:dbext_default_DBI_trace_level")?g:dbext_default_DBI_trace_level.'':'2')
    " Override certain values for different DBI drivers
    elseif a:name ==# "DBI_table_type_SQLAnywhere"       |return (exists("g:dbext_default_dbi_table_type_SQLAnywhere")?g:dbext_default_dbi_table_type_SQLAnywhere.'':'%TABLE%')
    elseif a:name ==# "DBI_view_type_SQLAnywhere"        |return (exists("g:dbext_default_dbi_view_type_SQLAnywhere")?g:dbext_default_dbi_table_type_SQLAnywhere.'':'%VIEW%')
    elseif a:name ==# "DBI_table_type_ASAny"             |return (exists("g:dbext_default_dbi_table_type_ASAny")?g:dbext_default_dbi_table_type_ASAny.'':'%TABLE%')
    elseif a:name ==# "DBI_view_type_ASAny"              |return (exists("g:dbext_default_dbi_view_type_ASAny")?g:dbext_default_dbi_table_type_ASAny.'':'%VIEW%')
    " Create additional SQL statements for the DBI layer to support listing procedures which is not supported by DBI
    elseif a:name ==# "DBI_list_proc_SQLAnywhere"  |return (exists("g:dbext_default_DBI_list_proc_SQLAnywhere")?g:dbext_default_DBI_list_proc_SQLAnywhere.'':'select p.proc_name, u.user_name from SYS.SYSPROCEDURE as p, SYS.SYSUSERPERM as u where p.creator = u.user_id and p.proc_name like ''dbext_replace_name%'' and u.user_name like ''dbext_replace_owner%'' order by proc_name')
    elseif a:name ==# "DBI_list_proc_ASAny"        |return (exists("g:dbext_default_DBI_list_proc_ASAny")?g:dbext_default_DBI_list_proc_ASAny.'':'select p.proc_name, u.user_name from SYS.SYSPROCEDURE as p, SYS.SYSUSERPERM as u  where p.creator = u.user_id and p.proc_name like ''%'' and u.user_name like ''%''  order by proc_name')
    elseif a:name ==# "DBI_list_proc_Oracle"       |return (exists("g:dbext_default_DBI_list_proc_Oracle")?g:dbext_default_DBI_list_proc_Oracle.'':'select object_name, owner from all_objects  where object_type IN (''PROCEDURE'', ''PACKAGE'', ''FUNCTION'') and object_name LIKE ''dbext_replace_name%'' order by object_name')
    elseif a:name ==# "DBI_list_proc_Sybase"       |return (exists("g:dbext_default_DBI_list_proc_Sybase")?g:dbext_default_DBI_list_proc_Sybase.'':'select convert(varchar,o.name), convert(varchar,u.name)   from sysobjects o, sysusers u  where o.uid=u.uid    and o.type=''P''    and o.name like ''dbext_replace_name%''  order by o.name')
    elseif a:name ==# "DBI_list_proc_DB2"          |return (exists("g:dbext_default_DBI_list_proc_DB2")?g:dbext_default_DBI_list_proc_DB2.'':'select CAST(procname AS VARCHAR(40)) AS procname      , CAST(procschema AS VARCHAR(15)) AS procschema      , CAST(definer AS VARCHAR(15)) AS definer      , parm_count      , deterministic      , fenced      , result_sets   from syscat.procedures  where procname like ''dbext_replace_name%''  order by procname')
    elseif a:name ==# "DBI_list_proc_mysql"        |return (exists("g:dbext_default_DBI_list_proc_mysql")?g:dbext_default_DBI_list_proc_mysql.'':'SELECT specific_name, routine_schema    FROM INFORMATION_SCHEMA.ROUTINES  WHERE specific_name  like ''dbext_replace_name%''    AND routine_schema like ''dbext_replace_owner%'' ')
    elseif a:name ==# "DBI_list_proc_PGSQL"        |return (exists("g:dbext_default_DBI_list_proc_PGSQL")?g:dbext_default_DBI_list_proc_PGSQL.'':'SELECT p.proname, pg_get_userbyid(u.usesysid)   FROM pg_proc p, pg_user u  WHERE p.proowner = u.usesysid    AND u.usename  like ''dbext_replace_owner%''    AND p.proname  like ''dbext_replace_name%''  ORDER BY p.proname')
    elseif a:name ==# "DBI_list_proc_SQLSRV"       |return (exists("g:dbext_default_DBI_list_proc_SQLSRV")?g:dbext_default_DBI_list_proc_SQLSRV.'':'select convert(varchar,o.name) proc_name, convert(varchar,u.name) proc_owner   from sysobjects o, sysusers u  where o.uid=u.uid    and o.xtype=''P''    and o.name like ''dbext_replace_name%''  order by o.name')
    " Create additional SQL statements for the DBI layer to support creating a dictionary for procedures which is not supported by DBI
    elseif a:name ==# "DBI_dict_proc_SQLAnywhere"  |return (exists("g:dbext_default_DBI_dict_proc_SQLAnywhere")?g:dbext_default_DBI_dict_proc_SQLAnywhere.'':'select u.user_name ||''.''|| p.proc_name from SYS.SYSPROCEDURE as p, SYS.SYSUSERPERM as u  where p.creator = u.user_id order by u.user_name, proc_name')
    elseif a:name ==# "DBI_dict_proc_ASAny"        |return (exists("g:dbext_default_DBI_dict_proc_ASAny")?g:dbext_default_DBI_dict_proc_ASAny.'':'select u.user_name ||''.''|| p.proc_name from SYS.SYSPROCEDURE as p, SYS.SYSUSERPERM as u  where p.creator = u.user_id order by u.user_name, proc_name')
    elseif a:name ==# "DBI_dict_proc_Oracle"       |return (exists("g:dbext_default_DBI_dict_proc_Oracle")?g:dbext_default_DBI_dict_proc_Oracle.'':'select owner||''.''||object_name from all_objects where object_type IN (''PROCEDURE'', ''PACKAGE'', ''FUNCTION'') order by object_name')
    elseif a:name ==# "DBI_dict_proc_Sybase"       |return (exists("g:dbext_default_DBI_dict_proc_Sybase")?g:dbext_default_DBI_dict_proc_Sybase.'':'select convert(varchar,u.name)||''.''||convert(varchar,o.name)   from sysobjects o, sysusers u  where o.uid=u.uid    and o.type=''P'' order by o.name')
    elseif a:name ==# "DBI_dict_proc_DB2"          |return (exists("g:dbext_default_DBI_dict_proc_DB2")?g:dbext_default_DBI_dict_proc_DB2.'':'select CAST(procname AS VARCHAR(40)) AS procname from syscat.procedures order by procname')
    elseif a:name ==# "DBI_dict_proc_mysql"        |return (exists("g:dbext_default_DBI_dict_proc_mysql")?g:dbext_default_DBI_dict_proc_mysql.'':'SELECT CONCAT_WS(''.'', routine_schema,specific_name) FROM INFORMATION_SCHEMA.ROUTINES  WHERE specific_name  like ''%''    AND routine_schema like ''%'' ')
    elseif a:name ==# "DBI_dict_proc_PGSQL"        |return (exists("g:dbext_default_DBI_dict_proc_PGSQL")?g:dbext_default_DBI_dict_proc_PGSQL.'':'SELECT pg_get_userbyid(u.usesysid)||''.''||p.proname  FROM pg_proc p, pg_user u  WHERE p.proowner = u.usesysid  ORDER BY p.proname ')
    elseif a:name ==# "DBI_dict_proc_SQLSRV"       |return (exists("g:dbext_default_DBI_dict_proc_SQLSRV")?g:dbext_default_DBI_dict_proc_SQLSRV.'':'select convert(varchar,u.name)+''.''+convert(varchar,o.name)   from sysobjects o, sysusers u  where o.uid=u.uid    and o.xtype=''P'' order by o.name ')
    " Create additional SQL statements for the DBI layer to support describing a procedure which is not supported by DBI
    elseif a:name ==# "DBI_desc_proc_SQLAnywhere"  |return (exists("g:dbext_default_DBI_desc_proc_SQLAnywhere")?g:dbext_default_DBI_desc_proc_SQLAnywhere.'':'select *   from SYS.SYSPROCPARMS as pp  where pp.parmtype = 0    and pp.procname = ''dbext_replace_name''   ')
    elseif a:name ==# "DBI_desc_proc_ASAny"        |return (exists("g:dbext_default_DBI_desc_proc_ASAny")?g:dbext_default_DBI_desc_proc_ASAny.'':'select *   from SYS.SYSPROCPARMS as pp  where pp.parmtype = 0    and pp.procname = ''dbext_replace_name''   ')
    elseif a:name ==# "DBI_desc_proc_Oracle"       |return (exists("g:dbext_default_DBI_desc_proc_Oracle")?g:dbext_default_DBI_desc_proc_Oracle.'':'select object_name, owner from all_objects  where object_type IN (''PROCEDURE'', ''PACKAGE'', ''FUNCTION'') and object_name LIKE ''dbext_replace_name%'' order by object_name')
    elseif a:name ==# "DBI_desc_proc_Sybase"       |return (exists("g:dbext_default_DBI_desc_proc_Sybase")?g:dbext_default_DBI_desc_proc_Sybase.'':'exec sp_help dbext_replace_owner.dbext_replace_name ')
    elseif a:name ==# "DBI_desc_proc_DB2"          |return (exists("g:dbext_default_DBI_desc_proc_DB2")?g:dbext_default_DBI_desc_proc_DB2.'':'select ordinal      , CAST(parmname AS VARCHAR(40)) AS parmname      , CAST(typename AS VARCHAR(10)) AS typename      , length      , scale      , CAST(nulls AS VARCHAR(1)) AS nulls      , CAST(procschema AS VARCHAR(30)) AS procschema   from syscat.procparms  where procname = ''dbext_replace_name%''   order by ordinal   ')
    elseif a:name ==# "DBI_desc_proc_mysql"        |return (exists("g:dbext_default_DBI_desc_proc_mysql")?g:dbext_default_DBI_desc_proc_mysql.'':'describe dbext_replace_owner.dbext_replace_name ')
    elseif a:name ==# "DBI_desc_proc_PGSQL"        |return (exists("g:dbext_default_DBI_desc_proc_PGSQL")?g:dbext_default_DBI_desc_proc_PGSQL.'':'SELECT p.*   FROM pg_proc p, pg_type t, pg_language l  WHERE p.proargtypes = t.oid    AND p.prolang = t.oid    AND p.proname = ''dbext_replace_name''   ORDER BY p.pronargs  ')
    elseif a:name ==# "DBI_desc_proc_SQLSRV"       |return (exists("g:dbext_default_DBI_desc_proc_SQLSRV")?g:dbext_default_DBI_desc_proc_SQLSRV.'':'exec sp_help dbext_replace_owner.dbext_replace_name')
    else                                           |return ''
    endif
endfunction

function! dbext#DB_completeSettings(ArgLead, CmdLine, CursorPos)
    let items = copy(s:all_params_mv)
    call extend(items, s:config_dbi_mv)
    if a:ArgLead != ''
        let items = filter(items, "v:val =~ '^".a:ArgLead."'")
    endif
    return items
endfunction

function! dbext#DB_completeVariable(ArgLead, CmdLine, CursorPos)
    if exists('b:dbext_sqlvar_mv')
        let items = []
        for [k,v] in items(b:dbext_sqlvar_mv)
            call add(items, k.'='.v)
        endfor
        if a:ArgLead != ''
            let items = filter(items, "v:val =~ '^".substitute(a:ArgLead,"'","''",'g')."'")
        endif
        return items
    else
        return []
    endif
endfunction

function! dbext#DB_completeTables(ArgLead, CmdLine, CursorPos)
    let tables = []
    let table_file = s:DB_get("dict_table_file" )

    if table_file == ''
        exec 'DBCompleteTables'
        let table_file = s:DB_get("dict_table_file" )
    endif

    if filereadable(table_file)
        let tables = readfile(table_file)
        if a:ArgLead != ''
            " let expr = 'v:val '.(g:omni_sql_ignorecase==1?'=~?':'=~#').' "\\(^'.base.'\\|^\\(\\w\\+\\.\\)\\?'.base.'\\)"'
            let expr = 'v:val =~? "\\(^'.a:ArgLead.'\\|^\\(\\w\\+\\.\\)\\?'.a:ArgLead.'\\)"'
            let tables = filter(tables, expr)
        endif
    endif
    return tables
endfunction

"" Sets global parameters to default values.
function! s:DB_resetGlobalParameters()

    if !exists("g:dbext_suppress_version_warning")
        let saveA = @a

        " Check for previous options for dbext and tell the user
        " the must update the parameters
        redir  @a
        silent! exec 'let'
        redir END

        if @a =~ 'db_ext'
            call s:DB_warningMsg("You have used a previous version of db_ext. ")
            call s:DB_warningMsg("The configuration parameters have changed.  ")
            call s:DB_warningMsg("Please read through the dbext documentation to ")
            call s:DB_warningMsg("determine what changes are necessary in your")
            call s:DB_warningMsg("vimrc file.")
            call s:DB_warningMsg("When all *db_ext* variables have been replaced")
            call s:DB_warningMsg("with *dbext* variables this message will")
            call s:DB_warningMsg("no longer be displayed.")
            call s:DB_warningMsg("To suppress this message, add this to your")
            call s:DB_warningMsg("vimrc file:")
            call s:DB_warningMsg("let g:dbext_suppress_version_warning = 1")
            call s:DB_warningMsg(":h dbext.txt")
            call s:DB_warningMsg("")
        endif
        let @a = saveA
    endif

    return 1
endfunction

" The only buffer variable that must exist is the 
" database type.
function! s:DB_validateBufferParameters()
    let no_defaults = 0
    let rc          = -1

    " If a database type has been chosen, do not prompt for connection
    " information
    let found = index( s:db_types_mv, s:DB_get("type", no_defaults) )
    if found > -1
        call s:DB_set("buffer_defaulted", "1")
        let rc = 1
    else
        call s:DB_set("buffer_defaulted", "0")
        let rc = -1
    endif

    return rc
endfunction

" Sets buffer parameters to global values. This is called when the user adds
" new buffer to set up the buffer defaults
function! s:DB_resetBufferParameters(use_defaults)
    let no_defaults  = 0
    let retval       = -2

    " Reset configuration parameters to defaults
    for param in s:config_params_mv
        call s:DB_set(param, s:DB_get(param))
    endfor

    " Allow the user to define an autocmd to dynamically
    " setup their connection information.
    silent! doautocmd User dbextPreConnection

    " Reset connection parameters to either blanks or defaults
    " depending on what was passed into this function
    " Loop through and prompt the user for all buffer
    " connection parameters.
    " Calling this function can be nested, so we must generate
    " a unique IterCreate name.
    for param in s:conn_params_mv
        if a:use_defaults == 0
            call s:DB_set(param, "")
        else
            " Only set the buffer variable if the default value
            " is not '@ask'
            if s:DB_getDefault(param) !=? '@ask'
                let value = s:DB_get(param)
                if value == -1 
                    let retval = value
                    break
                else
                    let retval = s:DB_set(param, value)
                endif
            endif
        endif
    endfor

    " if retval == -1 
    "     return retval
    " endif

    " If a database type has not been chosen, do prompt
    " for connection information
    if s:DB_get("type", no_defaults) == "" 
                \ && a:use_defaults == 1
                \ && retval == -2
        call s:DB_promptForParameters()
    endif

    " if s:DB_get('filetype') == ''
    "     let s:DB_set('filetype') = &filetype
    " endif

    " call s:DB_validateBufferParameters()
    let retval = s:DB_validateBufferParameters()

    return retval
endfunction

"" Returns a string containing a vim command where the named variable gets the
" current value.
" If value of g:dbext_type is 'MYSQL' then >
"       s:DB_varToString("g:dbext_default_type")
" returns >
"       let g:dbext_type = 'MYSQL'
" FIXME: don't forget to transform string if it contains special chars.
" (eg: return \n instead of new line) Priority: low.
function! s:DB_varToString(name)
    if exists(a:name)
        if {a:name} == ""
            let value = '""'
        else
            let value = {a:name}
        endif
        return 'let ' . a:name . ' = "' . value . "\"\n"
    else
        return ""
    endif
endfunction

"FIXME: Csinálni kell erre egy kommandot.
function! s:DB_getParameters(scope)
    "scope must be 'b', 'g', 'd' (buffer, global, default)
    if (a:scope == "b")
        let prefix = "b:dbext_"
    elseif (a:scope == "g")
        let prefix = "g:dbext_"
    elseif (a:scope == "d")
        let prefix = "g:dbext_default_"
    else
        call s:DB_warningMsg("dbext:Invalid scope in parameter: '" . a:scope . "'")
        return ""
    endif
    let variables = ""

    for param in s:all_params_mv
        let variables = variables . s:DB_varToString(prefix . param)
    endfor

    return variables
endfunction

function! s:DB_promptForParameters(...)

    " call s:DB_set('prompting_user', 1)
    let b:dbext_prompting_user = 1
    let no_default = 1
    let param_prompted = 0
    let param_value = ''

    " The retval is only set when an optional parameter name 
    " is passed in from DB_get
    let retval = ""

    " Loop through and prompt the user for all buffer
    " connection parameters
    for param in s:conn_params_mv
        if (a:0 > 0)
            " If the specified parameter has already been prompted
            " for, exit this loop
            if param_prompted == 1
                break
            endif

            " By default prompt for all parameters, unless
            " a certain parameter name is supplied.
            if (a:1 !=?  param)
                continue
            endif
            let param_prompted = 1
        endif

        if param ==# 'type'
            let l:old_value = 1 + 
                        \ index(s:db_types_mv, s:DB_get(param, no_default))

            let l:new_value = s:DB_getInput( 
                        \ s:DB_getDefault("prompt_" . param), 
                        \ l:old_value,
                        \ "-1"
                        \ )
        elseif param ==# 'profile'
            if empty(s:conn_profiles_mv)
                continue
            endif

            let l:old_value = 1 + 
                        \ index(s:conn_profiles_mv, s:DB_get(param, no_default))

            let l:new_value = s:DB_getInput( 
                        \ s:DB_getDefault("prompt_" . param), 
                        \ l:old_value,
                        \ "-1"
                        \ )
        elseif param ==# 'integratedlogin'
            " Integrated login is only supported on Windows platforms
            if !has("win32")
                continue
            elseif count(s:intlogin_types_mv, s:DB_get("type") ) == 0
                " If the chosen datatype type does not support 
                " integrated logins, do not prompt for it
                continue
            endif
            let diag_prompt = s:DB_getDefault("prompt_" . param)
            " Default the choice to 1 - the "No" button
            " Otherwise add 1, if already selected to choose 
            " the 2nd button - "Yes"
            let l:old_value = (s:DB_get(param, no_default) == '' ? 0 : (s:DB_get(param, no_default)) )
            let l:new_value = confirm( 
                        \ diag_prompt,
                        \ "&No\n&Yes\n&Cancel",
                        \ (l:old_value+1)
                        \ )
            if l:new_value == 3
                let l:new_value = "-1"
            else
                let l:new_value = l:new_value - 1
            endif
        else
            if ( s:DB_get("integratedlogin") == '1' &&
                        \ ( (param ==# 'user') || 
                        \   (param ==# 'passwd')  )      )
                " Ignore user and password if using integrated logins
                continue
            endif

            let diag_prompt = s:DB_getDefault("prompt_" . param)
            let l:old_value = s:DB_get(param, no_default)
            let l:new_value = s:DB_getInput( 
                        \ diag_prompt,
                        \ l:old_value,
                        \ "-1"
                        \ )
        endif
        " If the user cancelled the input, break from the loop
        " this is a new 602 feature
        if l:new_value == "-1"
            let retval = l:new_value
            break
        elseif l:new_value !=# l:old_value
            " Make the comparison between the new_value and old_value
            " case sensitive, since passwords and userids are often
            " case sensitive.
            " This comparison would have short circuited the change, 
            " and ignored it considering it a non change.
            let retval = l:new_value

            if l:old_value =~ '@askg'
                " Handle the special case of setting a global (@askg) value.
                " There is no need to do something for the buffer (@askb) 
                " since all changes affect the buffer variables.
                call s:DB_setGlobal(param, l:new_value)
            endif

            if param == "profile"
                " If using the DBI layer, drop any connections which may be active
                " before switching profiles
                if s:DB_get('type') =~ '\<DBI\>\|\<ODBC\>'
                    call dbext#DB_disconnect()
                endif

                if l:new_value > 0 && l:new_value <= 
                            \ len(s:conn_profiles_mv)
                    let retval = s:conn_profiles_mv[(l:new_value-1)]
                    call s:DB_set(param, retval)
                else
                    call s:DB_set(param, "")
                    if l:new_value == 0 
                        continue
                    endif
                endif

                if strlen(s:DB_get('type')) > 0
                    break
                endif
            elseif param == "type"
                if l:new_value > 0 && l:new_value <= 
                            \ len(s:db_types_mv)
                    let retval = s:db_types_mv[(l:new_value-1)]
                    call s:DB_set(param, retval)
                else
                    call s:DB_set(param, "") 
                endif
            else
                " Force string comparison
                if l:old_value.'' ==? '@ask'
                    " If the default value is @ask, then do not set the 
                    " buffer parameter, just return the value.
                    " The next time we execute something, we will be
                    " prompted for this value again.
                    break
                endif

                call s:DB_set(param, l:new_value) 

            endif
        endif
    endfor

    call s:DB_validateBufferParameters()

    if !has("gui_running") && v:version < 602
        " Work around an issue with the input command and redir.  The file
        " would be offset by the length of the previous input text.
        " This has been fixed in Vim 6.2 but for backwards compatability, we
        " are leaving this code as is
        echo "\n" 
    endif

    if (s:DB_get('type') =~ '\<DBI\>\|\<ODBC\>') 
        " If we have changed any of our connection parameters
        " force a disconnect or dbext_dbi.vim will simply
        " use the existing connection for this buffer.
        call dbext#DB_disconnect()
    endif

    " call s:DB_set('prompting_user', 0)
    let b:dbext_prompting_user = 0

    return retval
endfunction

function! dbext#DB_checkModeline()
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
            let mdl_options = matchstr(getline("."), pattern . '\s*\zs\(.*\)')
            " Based on the filetype, there could be comment indicators
            " in the string, so we need to strip these based on the 
            " &comments option
            " A simple example:
            "     /* dbext:...     */
            let mdl_options = s:DB_stripComments(mdl_options)
            " Since a modeline exists, clear any existing defaults
            " connection parameters
            let no_defaults = 0
            let rc = s:DB_resetBufferParameters(no_defaults)
            " if rc == -1
            "     break
            " endif

            let rc = dbext#DB_setMultipleOptions(mdl_options)
            if rc > -1
                call s:DB_validateBufferParameters()
            endif
        else
            if( line(".") < from_bottom_line )
                silent exec 'normal! '.from_bottom_line.'G'.col(".")."\<bar>"
            endif
        endif
    endwhile

    let @/ = saveSearch
    execute savePos
    return rc
endfunction

function! s:DB_stripLeadFollowQuotesSpace(str)
    " Strip leading or following quotes, single or double
    let str = substitute(a:str, 
                \ '^\s*'.'["'."']".'\?\(.*\)'.'\s*$',
                \ '\1', 'g' )
    " Had to do this in two steps since .* was too greedy and
    " did not allows the quotes to be conditional
    let str = substitute(str, 
                \ '\(.*\)'.'["'."']".'$',
                \ '\1', 'g' )
    return str
    return substitute(a:str, 
                \ '^\s*'.'["'."']".'\?\(.*\)'.'["'."']".'\?\s*$',
                \ '\1', 'g' )
endfunction

function! s:DB_stripLeadFollowSpaceLines(str)
    " Thanks to Benji Fisher
    " This seems to remove leading spaces on Linux:
    "     :echo substitute(@a, '\(^\|\n\)\zs\s\+', '', 'g')
    " And this should remove trailing spaces:  
    "     :echo substitute(@a, '\s\+\ze\($\|\n\)', '', 'g')
    "
    " Remove any blank lines in the output:
    " This substitution is tough since we are dealing with a 
    " string, not a buffer.
    " '^\(\s*\n\)*\    - From the beginning of the string, 
    "                    remove any blank lines
    " |\n\s*\n\@='     - Any middle or ending blank lines
    " thanks to suresh govindachari and klaus bosau
    "let stripped = substitute(a:str, 
    "            \ '^\(\s*\n\)*\|\n\s*\n\@=', 
    "            \ '', 'g')
    "
    " Hmm, the sent the CPU to 100%, unless I broke it into 2
    " First, from each line, removing any beginning spaces by removing
    " all newlines and spaces with just a newline
    " let stripped = substitute(a:str, '[ \t\r\n]\+', '\n', 'g')
    " This has the side effect of adding a blank line at the top
    " let stripped = substitute(stripped, '^[\r\n]\+', '', '')
    let stripped = substitute(a:str, '^[\r\n]\+', '', '')
    " Now take care of the other end of the string
    let stripped = substitute(stripped, '\([ \t]\+\)\([\r\n]\+\)', '\2', 'g')
    
    " Albie patch
    " Unfortunately, the following substitute concats the first 2 lines, to 
    " create a space on the first line
    " let stripped = substitute( stripped, '^\s*\(.\{-}\)[ \t\r\n]*$', '\1\n', '' )
    let stripped = substitute(stripped, '^\|[\n]\zs\s*\(.\{-}\)[ \t]*\ze[\r\n$]', '\1', 'g' )
    let stripped = substitute(stripped, '^\s\+', '', '')
    return stripped
endfunction

function! s:DB_getCommentChars()
    let rc = 0
    let comment_chars = ""
    if &comments != ""
        " Based on filetypes, determine what all the comment characters are
        let comment_chars = &comments
        " Escape any special characters
        let comment_chars = substitute(comment_chars, '[*/$]', '\\&', 'g' )
        " Convert the beginning option to a \|
        " let comment_chars = substitute(comment_chars, '^.\{-}:', '\\|', '' )
        " Convert remaining options a separators \|
        let comment_chars = substitute(comment_chars, ',.\{-}:', '\\|', 'g')
    endif

    return comment_chars
endfunction

function! s:DB_stripComments(mdl_options)
    " Put the comment characters together so that the dbext: modeline will
    " automatically strip spaces and comments characters from the end of it.
    let strip_end_expr = ':\?\s*\(,\|'.s:DB_getCommentChars().'\)\?\s*$'

    return substitute(a:mdl_options, strip_end_expr, '', '')
endfunction

function! dbext#DB_setMultipleOptions(multi_options, ...)
    let rc = 0
    let multi_options = a:multi_options

    for parms in a:000
      echon ' ' . parms
      let multi_options = multi_options . parms
    endfor
    " Strip leading or following quotes, single or double
    let options_cs = s:DB_stripLeadFollowQuotesSpace(multi_options)

    " replace all "\:" sequences with \!
    let options_cs = substitute(options_cs, '\\:', '\\!', '' )

    " Chose a bad separator (:), and it is too late to choose another one
    " with the plugin available.
    " On win32 platforms, must do something special for the bin_path
    " parameter, since it can have C:\
    if has("win32")
        " Replace the : with a !, and correct it later
        let options_cs = substitute(options_cs, 'bin_path\s*=\s*.\zs:\ze\\', 
                    \ '!', '' )
        let options_cs = substitute(options_cs, '\w\+_bin\s*=\s*.\zs:\ze\\', 
                    \ '!', '' )
        let options_cs = substitute(options_cs, 'dbname\s*=\s*.\zs:\ze\\', 
                    \ '!', '' )
    endif

    " Special case due to regular expression syntax
    if options_cs =~ '\<variable_def_regex\>'
        let opt_value = substitute(options_cs, 'variable_def_regex\s*=\s*', '', '')
        if opt_value =~ '^,'
            let l:variable_def_regex = s:DB_get('variable_def_regex')
            " if escape(','.l:variable_def_regex, '\\/.*$^~[]') !~ escape(opt_value, '\\/.*$^~[]')
            if ','.l:variable_def_regex !~ escape(opt_value, '\\/.*$^~[]')
                " Append to existing values if not already present
                call s:DB_set('variable_def_regex', l:variable_def_regex.opt_value)
            endif
        else
            call s:DB_set('variable_def_regex', opt_value)
        endif
    else
        " Convert the comma separated list into a List
        let options_mv = split(options_cs, ':')
        " Loop through and prompt the user for all buffer connection parameters.
        for option in options_mv
            if strlen(option) > 0
                " Retrieve the option name 
                let opt_name  = matchstr(option, '.\{-}\ze=')
                let opt_value = matchstr(option, '=\zs.*')
                let opt_value = s:DB_stripLeadFollowQuotesSpace(opt_value)
     
                " replace all "\!" sequences with :
                let opt_value = substitute(opt_value, '\\!', ':', '' )

                if has("win32") && (
                            \ opt_name ==? 'bin_path'
                            \ || 
                            \ opt_name =~? '\w\+_bin'
                            \ || 
                            \ opt_name ==? 'dbname'
                            \ )
                    " Now flip the ! back to a :
                    let opt_value = substitute(opt_value, '!', ':', '')
                endif
                call s:DB_set(opt_name, opt_value)
            endif
        endfor
    endif

    return rc
endfunction 

function! s:DB_fullPath2Bin(executable_name) 
    " If the database tools directory is not in the path
    " then the user can specify a fully qualified address
    " to the binaries.
    " This can also include environment variables.
    " So expand and replace slashes / spaces/ quotes
    " to make this work on both windows and *nix platforms
    if s:DB_get("bin_path") != ""
        " Expand environment variables
        let full_bin = expand(s:DB_get("bin_path"))
        " Remove any double quotes
        let full_bin = substitute( full_bin, '"', "", "g" )
        " Remove any trailing spaces and a ending slash
        let full_bin = substitute( full_bin, "[\\\\\/]\s*$", "", "ge" )
        if has("win32") 
            let full_bin = full_bin . "\\" . a:executable_name
        else
            let full_bin = full_bin . "/" . a:executable_name
        endif
        if has("win32") && full_bin =~ " "
            let full_bin = '"' . full_bin . '"'
        endif
    else
        let full_bin = a:executable_name
    endif
    return full_bin
endfunction 
"}}}

" ASA exec {{{
function! s:DB_ASA_execSql(str)
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let terminator = dbext#DB_getWType("cmd_terminator")

    let output = dbext#DB_getWType("cmd_header") 
    " Check if a login_script has been specified
    let output = output.s:DB_getLoginScript(s:DB_get("login_script"))
    let output = output.a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(terminator) . 
                \ '['."\n".' \t]*$'
        let output = output . terminator
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(dbext#DB_getWType("bin"))

    if s:DB_get("host") != "" || s:DB_get("port") != ""
        let links = 'tcpip(' .
                \ s:DB_option('host=', s:DB_get("host"), ';') .
                \ s:DB_option('port=', s:DB_get("port"), '') .
                \ ')'
    else
        let links = ""
    endif
    let cmd = dbext_bin .  ' ' . dbext#DB_getWType("cmd_options") . ' ' .
                \ s:DB_option('-onerror ', dbext#DB_getWType("on_error"), ' ') .
                \ ' -c "' .
                \ s:DB_option('uid=', s:DB_get("user"), ';') .
                \ s:DB_option('pwd=', s:DB_get("passwd"), ';') .
                \ s:DB_option('dsn=', s:DB_get("dsnname"), ';') .
                \ s:DB_option('eng=', s:DB_get("srvname"), ';') .
                \ s:DB_option('dbn=', s:DB_get("dbname"), ';') .
                \ s:DB_option('links=', links, ';') .
                \ s:DB_option('', dbext#DB_getWTypeDefault("extra"), '') 
    if has("win32") && s:DB_get("integratedlogin") == 1
        let cmd = cmd . 
                \ s:DB_option('int=', 'yes', ';') 
    endif
    let cmd = cmd .  '" ' . 
                \ ' read ' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output, "")

    return result
endfunction

function! s:DB_ASA_describeTable(table_name)
    let owner  = s:DB_getObjectOwner(a:table_name)
    let object = s:DB_getObjectName(a:table_name)
    let owner  = ( strlen(owner) > 0 ? owner : '' ) 
    " return s:DB_ASA_execSql("call sp_jdbc_columns('".object."', '".owner."');")
    let sql =  ''.
                \ "select * ".
                \ "  from SYS.SYSCOLUMNS as sc ".
                \ " where sc.tname = '".object."' "
                " \ "select sc.creator ".
                " \ "     , sc.tname ".
                " \ "     , sc.cname ".
                " \ "     , sc.coltype ".
                " \ "     , sc.in_primary_key ".
                " \ "     , sc.nulls ".
                " \ "     , sc.length ".
                " \ "     , sc.default_value ".
                " \ "     , sc.colno ".
                " \ "  from SYS.SYSCOLUMNS as sc ".
                " \ " where sc.tname = '".object."' "

    if owner != ''
        let sql = sql .
                    \" and sc.creator = '".owner."' "
    endif
    let sql = sql .
                \ " order by sc.colno asc "
    return s:DB_ASA_execSql(sql)
endfunction

function! s:DB_ASA_describeProcedure(proc_name)
    let owner  = s:DB_getObjectOwner(a:proc_name)
    let object = s:DB_getObjectName(a:proc_name)
    let owner  = ( strlen(owner) > 0 ? owner : '' ) 
    " return s:DB_ASA_execSql("call sp_sproc_columns('".object."', '".owner."');")
    let sql =  ''.
                \ "select * ".
                \ "  from SYS.SYSPROCPARMS as pp ".
                \ " where pp.parmtype = 0 ".
                \ "   and pp.procname = '".object."' "

    if owner != ''
        let sql = sql .
                    \" and pp.creator = '".owner."' "
    endif
    " let sql = sql .
    "             \ " order by pp.parm_id asc "
    return s:DB_ASA_execSql(sql)
    " let sql =  ''.
    "             \ "select u.user_name ".
    "             \ "     , p.proc_name ".
    "             \ "     , pp.parm_name ".
    "             \ "     , d.domain_name ".
    "             \ "     , d.".'"precision" '.
    "             \ "     , pp.width ".
    "             \ "     , pp.scale ".
    "             \ "     , IFNULL(pp.".'"default",'." 'Y', 'N') as allows_nulls ".
    "             \ "     , CASE  ".
    "             \ "       WHEN (pp.parm_mode_in = 'Y' AND pp.parm_mode_out = 'Y') THEN 'IO' ".
    "             \ "       WHEN (pp.parm_mode_in = 'Y') THEN 'I' ".
    "             \ "       ELSE 'N' ".
    "             \ "       END as in_out ".
    "             \ "     , pp.parm_id ".
    "             \ "  from SYS.SYSPROCEDURE as p ".
    "             \ "     , SYS.SYSPROCPARM as pp ".
    "             \ "     , SYS.SYSDOMAIN as d ".
    "             \ "     , SYS.SYSUSERPERM as u ".
    "             \ " where p.proc_id = pp.proc_id ".
    "             \ "   and pp.domain_id = d.domain_id ".
    "             \ "   and pp.parm_type = 0 ".
    "             \ "   and p.creator = u.user_id ".
    "             \ "   and p.proc_name = '".object."' "

    " if owner != ''
    "     let sql = sql .
    "                 \" and u.user_name = '".owner."' "
    " endif
    " let sql = sql .
    "             \ " order by pp.parm_id asc "
    " return s:DB_ASA_execSql(sql)
endfunction

function! s:DB_ASA_getListTable(table_prefix)
    let owner      = s:DB_getObjectOwner(a:table_prefix)
    let table_name = s:DB_getObjectName(a:table_prefix)
    let sql = ''.
                \ "select tname, creator " .
                \ "  from SYS.SYSCATALOG " .
                \ " where tname   like '" . table_name . "%' ".
                \ "   and creator like '" . owner . "%' ".
                \ " order by tname"
    return s:DB_ASA_execSql(sql)
    " return s:DB_ASA_execSql("call sp_jdbc_tables('" .
    "             \ table_name .
    "             \ "%', '" .
    "             \ owner .
    "             \ "%');")
endfunction

function! s:DB_ASA_getListProcedure(proc_prefix)
    let owner   = s:DB_getObjectOwner(a:proc_prefix)
    let object  = s:DB_getObjectName(a:proc_prefix)
    let sql = ''.
                \ "select p.proc_name, u.user_name " .
                \ "  from SYS.SYSPROCEDURE as p ".
                \ "     , SYS.SYSUSERPERM as u ".
                \ " where p.creator = u.user_id ".
                \ "   and p.proc_name like '".object."%' ".
                \ "   and u.user_name like '".owner."%' ".
                \ " order by proc_name"
    return s:DB_ASA_execSql(sql)
    " return s:DB_ASA_execSql(
    "             \ "call sp_jdbc_stored_procedures(null, null, ".
    "             \ "'".a:proc_prefix."%');")
endfunction

function! s:DB_ASA_getListView(view_prefix)
    let owner      = s:DB_getObjectOwner(a:view_prefix)
    let view_name  = s:DB_getObjectName(a:view_prefix)
    let query      = 
                \ "SELECT viewname, vcreator ".
                \ " FROM SYS.SYSVIEWS ".
                \ " WHERE viewname LIKE '".view_name."%'"
    if strlen(owner) > 0
        let query = query .
                    \ "   AND vcreator = '".owner."' ".
                    \ " ORDER BY vcreator, viewname;"
    else
        let query = query .
                    \ " ORDER BY vcreator, viewname;"
    endif
    return s:DB_ASA_execSql(query)
endfunction 

function! s:DB_ASA_getListColumn(table_name) 
    let owner      = s:DB_getObjectOwner(a:table_name)
    let table_name = s:DB_getObjectName(a:table_name)
    let query = ''.
                \ "select cname ".
                \ "  from SYS.SYSCOLUMNS as sc ".
                \ " where sc.tname = '".table_name."' "
    if strlen(owner) > 0
        let query = query .
                    \ "   AND sc.creator = '".owner."' "
    endif
    let query = query .
                \ " ORDER BY colno"
    let result = s:DB_ASA_execSql( query )
    return s:DB_ASA_stripHeaderFooter(result)
endfunction 

function! s:DB_ASA_stripHeaderFooter(result)
    " Strip off column headers ending with a newline
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-J>]", '', '' )
    let g:dbext_rows_affected = matchstr(stripped, '\((\)\?\(First\s\+\)\?\zs\d\+\ze row')
    " Strip off query statistics
    let stripped = substitute( stripped, '\((\)\?\(First\s\+\)\?\d\+ row\_.*', '', '' )
    " Strip off trailing spaces
    " let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*\(\n\)', '\1\2', 'g' )
    " Strip blank lines
    let stripped = substitute( stripped, '\(\n\)\(\n\)', '', 'g' )
    return stripped
endfunction 

function! s:DB_ASA_getDictionaryTable() 
    let result = s:DB_ASA_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"creator||'.'||":'')."tname " .
                \ "  from SYS.SYSCATALOG " .
                \ " order by ".(s:DB_get('dict_show_owner')==1?"creator, ":'')."tname"
                \ )
    return s:DB_ASA_stripHeaderFooter(result)
endfunction 

function! s:DB_ASA_getDictionaryProcedure() 
    let result = s:DB_ASA_execSql(
                \ "SELECT ".(s:DB_get('dict_show_owner')==1?"sup.user_name||'.'||":'')."sp.proc_name " .
                \ "  FROM SYS.SYSPROCEDURE sp, SYS.SYSUSERPERM sup  " .
                \ " WHERE sp.creator = sup.user_id  " .
                \ " ORDER BY ".(s:DB_get('dict_show_owner')==1?"sup.user_name, ":'')."sp.proc_name "
                \ )
    return s:DB_ASA_stripHeaderFooter(result)
endfunction 

function! s:DB_ASA_getDictionaryView() 
    let result = s:DB_ASA_execSql(
                \ "SELECT ".(s:DB_get('dict_show_owner')==1?"vcreator||'.'||":'')."viewname" .
                \ "  FROM SYS.SYSVIEWS " .
                \ " ORDER BY ".(s:DB_get('dict_show_owner')==1?"vcreator||'.'||":'')."viewname; "
                \ )
    return s:DB_ASA_stripHeaderFooter(result)
endfunction 
"}}}
" UltraLite exec {{{
function! s:DB_ULTRALITE_execSql(str)
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let terminator = dbext#DB_getWType("cmd_terminator")

    let output = dbext#DB_getWType("cmd_header") 
    " Check if a login_script has been specified
    let output = output.s:DB_getLoginScript(s:DB_get("login_script"))
    let output = output.a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(terminator) . 
                \ '['."\n".' \t]*$'
        let output = output . terminator
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(dbext#DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . dbext#DB_getWType("cmd_options") . ' ' .
                \ s:DB_option('-onerror ', dbext#DB_getWType("on_error"), ' ') .
                \ ' -c "' .
                \ s:DB_option('uid=', s:DB_get("user"), ';') .
                \ s:DB_option('pwd=', s:DB_get("passwd"), ';') .
                \ s:DB_option('dsn=', s:DB_get("dsnname"), ';') .
                \ s:DB_option('dbf=', s:DB_get("dbname"), ';') .
                \ s:DB_option('', dbext#DB_getWTypeDefault("extra"), '') 
    let cmd = cmd .  '" ' . 
                \ ' read ' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output, "")

    return result
endfunction

function! s:DB_ULTRALITE_describeTable(table_name)
    let owner  = s:DB_getObjectOwner(a:table_name)
    let object = s:DB_getObjectName(a:table_name)
    let owner  = ( strlen(owner) > 0 ? owner : '' ) 
    " return s:DB_ULTRALITE_execSql("call sp_jdbc_columns('".object."', '".owner."');")
    let sql =  ''.
                \ 'select CAST("column_name" as VARCHAR(40)) column_name, "domain", "nulls", CAST("default" as VARCHAR(40)) "default", "domain_info", sc."object_id", CAST(st."table_name" as VARCHAR(40)) table_name '.
                \ "  from SYSTABLE st ".
                \ "  join SYSCOLUMN sc ".
                \ "    on st.object_id = sc.table_id ".
                \ " where st.table_name = '".object."' "
                \ " order by sc.table_id, sc.object_id asc "
    return s:DB_ULTRALITE_execSql(sql)
endfunction

function! s:DB_ULTRALITE_describeProcedure(proc_name)
    echo 'UltraLite does not support stored procedures'
    return -1
endfunction

function! s:DB_ULTRALITE_getListTable(table_prefix)
    let owner      = s:DB_getObjectOwner(a:table_prefix)
    let table_name = s:DB_getObjectName(a:table_prefix)
    let sql = ''.
                \ "select CAST(table_name as VARCHAR(70)) table_name, table_type " .
                \ "  from SYSTABLE " .
                \ " where table_name   like '" . table_name . "%' ".
                \ " order by table_name"
    return s:DB_ULTRALITE_execSql(sql)
endfunction

function! s:DB_ULTRALITE_getListProcedure(proc_prefix)
    echo 'UltraLite does not support stored procedures'
    return -1
endfunction

function! s:DB_ULTRALITE_getListView(view_prefix)
    echo 'UltraLite does not support views'
    return -1
endfunction 

function! s:DB_ULTRALITE_getListColumn(table_name) 
    let owner      = s:DB_getObjectOwner(a:table_name)
    let table_name = s:DB_getObjectName(a:table_name)
    let query = ''.
                \ "select column_name ".
                \ "  from SYSTABLE st ".
                \ "  join SYSCOLUMN sc ".
                \ "    on st.object_id = sc.table_id ".
                \ " where st.table_name = '".table_name."' "
                \ " order by sc.object_id asc "
    let result = s:DB_ULTRALITE_execSql( query )
    return s:DB_ULTRALITE_stripHeaderFooter(result)
endfunction 

function! s:DB_ULTRALITE_stripHeaderFooter(result)
    " Strip off column headers ending with a newline
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-J>]", '', '' )
    let g:dbext_rows_affected = matchstr(stripped, '\((\)\?\(First\s\+\)\?\zs\d\+\ze row')
    " Strip off query statistics
    let stripped = substitute( stripped, '(\(First\s\+\)\?\d\+ rows\_.*', '', '' )
    " Strip off trailing spaces
    " let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*\(\n\)', '\1\2', '' )
    return stripped
endfunction 

function! s:DB_ULTRALITE_getDictionaryTable() 
    let result = s:DB_ULTRALITE_execSql(
                \ "select table_name " .
                \ "  from SYSTABLE " .
                \ " order by table_name"
                \ )
    return s:DB_ULTRALITE_stripHeaderFooter(result)
endfunction 

function! s:DB_ULTRALITE_getDictionaryProcedure() 
    echo 'UltraLite does not support stored procedures'
    return -1
endfunction 

function! s:DB_ULTRALITE_getDictionaryView() 
    echo 'UltraLite does not support views'
    return -1
endfunction 
"}}}
" ASE exec {{{
function! s:DB_ASE_execSql(str)
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let terminator = dbext#DB_getWType("cmd_terminator")

    let output = dbext#DB_getWType("cmd_header") 
    " Check if a login_script has been specified
    let output = output.s:DB_getLoginScript(s:DB_get("login_script"))
    let output = output.a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(terminator) . 
                \ '['."\n".' \t]*$'
        let output = output . terminator
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(dbext#DB_getWType("bin"))

    let cmd = dbext_bin . ' ' .
                \ s:DB_option('',    dbext#DB_getWType("cmd_options"), ' ') .
                \ s:DB_option('-U ', s:DB_get("user"), ' ') .
                \ s:DB_option('-P ', s:DB_get("passwd"), ' ') .
                \ s:DB_option('-H ', s:DB_get("host"), ' ') .
                \ s:DB_option('-S ', s:DB_get("srvname"), ' ') .
                \ s:DB_option('-D ', s:DB_get("dbname"), ' ') .
                \ s:DB_option('', dbext#DB_getWTypeDefault("extra"), '') .
                \ ' -i ' . s:dbext_tempfile

    let result = s:DB_runCmd(cmd, output, "")

    return result
endfunction

function! s:DB_ASE_describeTable(table_name)
    return s:DB_ASE_execSql("exec sp_help ".a:table_name)
endfunction

function! s:DB_ASE_describeProcedure(procedure_name)
    return s:DB_ASE_execSql("exec sp_help ".a:procedure_name)
endfunction

function! s:DB_ASE_getListTable(table_prefix)
    let owner      = s:DB_getObjectOwner(a:table_prefix)
    let table_name = s:DB_getObjectName(a:table_prefix)
    let query =   "select convert(varchar,o.name), convert(varchar,u.name) ".
                \ "  from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid ".
                \ "   and o.type='U' ".
                \ "   and o.name like '".table_name."%' "
    if strlen(owner) > 0
        let query = query .
                    \ "   and u.name = '".owner."' "
    endif
    let query = query .
                \ " order by o.name"
    return s:DB_ASE_execSql( query )
endfunction

function! s:DB_ASE_getListProcedure(proc_prefix)
    let owner     = s:DB_getObjectOwner(a:proc_prefix)
    let proc_name = s:DB_getObjectName(a:proc_prefix)
    let query =   "select convert(varchar,o.name), convert(varchar,u.name) ".
                \ "  from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid ".
                \ "   and o.type='P' ".
                \ "   and o.name like '".proc_name."%' "
    if strlen(owner) > 0
        let query = query .
                    \ "   and u.name = '".owner."' "
    endif
    let query = query .
                \ " order by o.name"
    return s:DB_ASE_execSql( query )
endfunction

function! s:DB_ASE_getListView(view_prefix)
    let owner     = s:DB_getObjectOwner(a:view_prefix)
    let view_name = s:DB_getObjectName(a:view_prefix)
    let query =   "select convert(varchar,o.name), convert(varchar,u.name) ".
                \ "  from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid ".
                \ "   and o.type='V' ".
                \ "   and o.name like '".view_name."%' "
    if strlen(owner) > 0
        let query = query .
                    \ "   and u.name = '".owner."' "
    endif
    let query = query .
                \ " order by o.name"
    return s:DB_ASE_execSql( query )
endfunction 

function! s:DB_ASE_getListColumn(table_name) "{{{
    let owner      = s:DB_getObjectOwner(a:table_name)
    let table_name = s:DB_getObjectName(a:table_name)
    let query =   "select convert(varchar,c.name)                ".
                \ "  from sysobjects o, sysusers u, syscolumns c ".
                \ " where o.uid=u.uid                            ".
                \ "   and o.id=c.id                              ".
                \ "   and o.type='U'                             ".
                \ "   and o.name = '".table_name."' "
    if strlen(owner) > 0
        let query = query .
                    \ "   and u.name = '".owner."' "
    endif
    let query = query .
                \ " order by c.colid"
    let result = s:DB_ASE_execSql( query )
    return s:DB_ASE_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_ASE_stripHeaderFooter(result) "{{{
    " Strip off column headers ending with a newline
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-J>]", '', '' )
    let g:dbext_rows_affected = matchstr(stripped, '(\zs\d\+\ze row')
    " Strip off query statistics
    let stripped = substitute( stripped, '(\d\+ rows\_.*', '', '' )
    " Strip off trailing spaces
    " let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*\(\n\)', '\1\2', '' )
    return stripped
endfunction "}}}

function! s:DB_ASE_getDictionaryTable() "{{{
    let result = s:DB_ASE_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"convert(varchar,u.name)||'.'||":'')."convert(varchar,o.name)  ".
                \ "  from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid              ".
                \ "   and o.type='U'               ".
                \ " order by ".(s:DB_get('dict_show_owner')==1?"convert(varchar,u.name), ":'')."o.name"
                \ )
    return s:DB_ASE_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_ASE_getDictionaryProcedure() "{{{
    let result = s:DB_ASE_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"convert(varchar,u.name)||'.'||":'')."convert(varchar,o.name)  ".
                \ "  from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid              ".
                \ "   and o.type='P'               ".
                \ " order by ".(s:DB_get('dict_show_owner')==1?"convert(varchar,u.name), ":'')."o.name"
                \ )
    return s:DB_ASE_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_ASE_getDictionaryView() "{{{
    let result = s:DB_ASE_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"convert(varchar,u.name)||'.'||":'')."convert(varchar,o.name)  ".
                \ "  from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid              ".
                \ "   and o.type='V'               ".
                \ " order by ".(s:DB_get('dict_show_owner')==1?"convert(varchar,u.name), ":'')."o.name"
                \ )
    return s:DB_ASE_stripHeaderFooter(result)
endfunction "}}}
"}}}
" DB2 exec {{{
function! s:DB_DB2_execSql(str)
    " To create a connection to a DB2 server running on a different machine
    " you must start db2cmd.exe and issue the following:
    "         In the case below host_name is the name of remote machine
    "         server 60000, means the server is listening on port 60000
    "     catalog tcpip node devcons remote host_name server 60000 
    "         Setup an alias for the paritcular database running on
    "         that server.
    "     catalog db db2cn01d as what_ever_you_want at node devcons
    "         If you have a DSN that you want to connect through setup
    "         a mapping.
    "     catalog user odbc data source devcons
    "     catalog system odbc data source devcons (for system DSN)
    " Other commands:
    "     list node directory
    "     list database directory
    "     list odbc data sources
    "     uncatalogue ...
    " When you start db2cmd.exe you can type (for help):
    "     ?
    "     ? catalogue
    " To see what options are available for db2:
    "     Start db2cmd
    "     list command options
    "
    " In batch files I used the following
    "     -c close when done
    "     -w wait until command finishes
    "     -i don’t spawn a new cmd window
    "     -t don’t change the window title
    "     db2cmd -c -w -i –t “db2 -s -t ; -v -f dave.sql”
    " To see command line options
    "     cd IBM\SQLLIB\BIN
    "     db2cmd -w -i
    "     db2 ?      (db2 ? options)
    "     


    if dbext#DB_getWType("use_db2batch") == '1'
        " All defaults are specified in the DB_getDefault function.
        " This contains the defaults settings for all database types
        let terminator = dbext#DB_getWType("cmd_terminator")

        let output = dbext#DB_getWType("cmd_header") 
        " Check if a login_script has been specified
        let output = output.s:DB_getLoginScript(s:DB_get("login_script"))
        let output = output.a:str
        " Only include a command terminator if one has not already
        " been added
        if output !~ s:DB_escapeStr(terminator) . 
                    \ '['."\n".' \t]*$'
            let output = output . terminator
        endif

        exe 'redir! > ' . s:dbext_tempfile
        silent echo output
        redir END

        let dbext_bin = s:DB_fullPath2Bin(dbext#DB_getWType("bin"))

        let cmd = dbext_bin . ' ' . dbext#DB_getWType("cmd_options") . ' '
        if s:DB_get("user") != ""
            let cmd = cmd . ' -a ' . s:DB_get("user") . '/' .
                        \ s:DB_get("passwd") . ' '
        endif
        let cmd = cmd . 
                    \ s:DB_option(' ', dbext#DB_getWTypeDefault("extra"), ' ') .
                    \ s:DB_option('-d ', s:DB_get("dbname"), ' ') .
                    \ s:DB_option('-l ', dbext#DB_getWType("cmd_terminator"), ' ').
                    \ ' -f ' . s:dbext_tempfile

    else
        " Use db2cmd instead

        let connect_str = 'CONNECT ' .
                    \ s:DB_option('TO ', s:DB_get("dbname"), ' ') .
                    \ s:DB_option('USER ', s:DB_get("user"), ' ') .
                    \ s:DB_option('USING ', s:DB_get("passwd"), '') .
                    \ s:DB_option('', dbext#DB_getWType("cmd_terminator"), '') .
                    \ "\n"

        " All defaults are specified in the DB_getDefault function.
        " This contains the defaults settings for all database types
        let terminator = dbext#DB_getWType("cmd_terminator")

        let output = dbext#DB_getWType("db2cmd_cmd_header") . connect_str 
        " Check if a login_script has been specified
        let output = output.s:DB_getLoginScript(s:DB_get("login_script"))
        let output = output.a:str
        " Only include a command terminator if one has not already
        " been added
        if output !~ s:DB_escapeStr(terminator) . 
                    \ '['."\n".' \t]*$'
            let output = output . terminator
        endif

        exe 'redir! > ' . s:dbext_tempfile
        silent echo output
        redir END

        let bin_path = s:DB_get("bin_path")
        if strlen(bin_path) > 0 && has('win32')
            if $PATH !~ escape(expand(bin_path), '\\/.*$^~[]' ) 
                " If the bin_path specified is not in the $PATH
                " add it, this is only necessary when using db2cmd
                let $PATH = $PATH . ';' . expand(bin_path)
            endif
        endif

        let dbext_bin = s:DB_fullPath2Bin(dbext#DB_getWType("db2cmd_bin"))

        let cmd = dbext_bin .  ' ' . dbext#DB_getWType("db2cmd_cmd_options")
        let cmd = cmd . ' ' .  s:DB_option('', dbext#DB_getWTypeDefault("extra"), ' ') .
                    \ s:DB_option('-t', dbext#DB_getWType("cmd_terminator"), ' ') .
                    \ '-f ' . s:dbext_tempfile
    endif


    let result = s:DB_runCmd(cmd, output, "")

    return result
endfunction

function! s:DB_DB2_describeTable(table_name)
    let save_use_db2batch = dbext#DB_getWType("use_db2batch")
    call s:DB_setWType("use_db2batch", 0)

    call s:DB_DB2_execSql(
                \ "DESCRIBE TABLE ".a:table_name." SHOW DETAIL".
                \ dbext#DB_getWType("cmd_terminator") .
                \ "\n" .
                \ "DESCRIBE INDEXES FOR TABLE ".a:table_name." SHOW DETAIL"
                \ )

    call s:DB_setWType("use_db2batch", save_use_db2batch)
endfunction

function! s:DB_DB2_describeProcedure(procedure_name)
    let owner = toupper(s:DB_getObjectOwner( a:procedure_name ))
    let proc  = toupper(s:DB_getObjectName( a:procedure_name ))

    " Using CAST as VARCHAR to make the output more readable
    let  query =  "select ordinal " .
                \ "     , CAST(parmname AS VARCHAR(40)) AS parmname " .
                \ "     , CAST(typename AS VARCHAR(10)) AS typename " .
                \ "     , length " .
                \ "     , scale " .
                \ "     , CAST(nulls AS VARCHAR(1)) AS nulls " .
                \ "     , CAST(procschema AS VARCHAR(30)) AS procschema " .
                \ "  from syscat.procparms " .
                \ " where procname = '" . proc . "' "
    if strlen(owner) > 0
        let query = query . " and procschema = '" . owner . "' "
    endif

    let query = query . " order by ordinal"

    return s:DB_DB2_execSql( query )
endfunction

function! s:DB_DB2_getListTable(table_prefix)
    return s:DB_DB2_execSql(
                \ "select CAST(tabname AS VARCHAR(40)) AS tabname " .
                \ "     , CAST(tabschema AS VARCHAR(15)) AS tabschema " .
                \ "     , CAST(definer AS VARCHAR(15)) AS definer " .
                \ "     , card " .
                \ "  from syscat.tables ".
                \ " where tabname like '".a:table_prefix."%' ".
                \ " order by tabname")
endfunction

function! s:DB_DB2_getListProcedure(proc_prefix)
    return s:DB_DB2_execSql(
                \ "select CAST(procname AS VARCHAR(40)) AS procname " .
                \ "     , CAST(procschema AS VARCHAR(15)) AS procschema " .
                \ "     , CAST(definer AS VARCHAR(15)) AS definer " .
                \ "     , parm_count " .
                \ "     , deterministic " .
                \ "     , fenced " .
                \ "     , result_sets " .
                \ "  from syscat.procedures ".
                \ " where procname like '".a:proc_prefix."%' ".
                \ " order by procname")
endfunction

function! s:DB_DB2_getListView(view_prefix)
    return s:DB_DB2_execSql(
                \ "select CAST(viewname AS VARCHAR(40)) AS viewname " .
                \ "     , CAST(viewschema AS VARCHAR(15)) AS viewschema " .
                \ "     , CAST(definer AS VARCHAR(15)) AS definer " .
                \ "     , readonly " .
                \ "     , valid " .
                \ "  from syscat.views ".
                \ " where viewname like '".a:view_prefix."%' ".
                \ " order by viewname")
endfunction 

function! s:DB_DB2_getListColumn(table_name) 
    let owner      = toupper(s:DB_getObjectOwner(a:table_name))
    let table_name = toupper(s:DB_getObjectName(a:table_name))
    let query =   "select colname        ".
                \ "  from syscat.columns ".
                \ " where tabname =     '".table_name."' "
    if strlen(owner) > 0
        let query = query .
                    \ "   and tabschema = '".owner."' "
    endif
    let query = query .
                \ " order by colno"
    let result = s:DB_DB2_execSql( query )
    return s:DB_DB2_stripHeaderFooter(result)
endfunction 

function! s:DB_DB2_stripHeaderFooter(result) 
    if dbext#DB_getWType("use_db2batch") == '1'
        " Strip off column headers ending with a newline
        let stripped = substitute( a:result, '\_.*-\s*'."[\<C-J>]", '', '' )
        " Strip off trailing spaces
        " let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
        let stripped = substitute( stripped, '\(\<\w\+\>\)\s*\(\n\)', '\1\2', '' )
        let g:dbext_rows_affected = matchstr(stripped, 'Number of rows\s*\zs\d\+\ze')
        " Strip off query statistics
        let stripped = substitute( stripped, 'Number of rows\_.*', '', '' )
    else
        " Strip off column headers ending with a newline
        let stripped = substitute( a:result, '\_.*-\s*', '', '' )
        let g:dbext_rows_affected = matchstr(stripped, '\s*\zs\d\+\ze\s\+record(s)')
        " Strip off query statistics
        let stripped = substitute( stripped, "\n".'\s*\d\+\s\+record(s)\s\+selected\_.*', '', '' )
        " Strip off trailing spaces
        " let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
        let stripped = substitute( stripped, '\(\<\w\+\>\)\s*\(\n\)', '\1\2', '' )
    endif
    return stripped
endfunction 

function! s:DB_DB2_getDictionaryTable()
    let result = s:DB_DB2_execSql( 
                \ "select ".(s:DB_get('dict_show_owner')==1?"TRIM(CAST(tabschema AS VARCHAR(15))) || '.' || ":'').
                \ "       CAST(tabname AS VARCHAR(40)) AS tabschema_tabname " .
                \ "  from syscat.tables " .
                \ " order by ".(s:DB_get('dict_show_owner')==1?"tabschema, ":'')."tabname" 
                \ )
    return s:DB_DB2_stripHeaderFooter(result)
endfunction 

function! s:DB_DB2_getDictionaryProcedure()
    let result = s:DB_DB2_execSql( 
                \ "select ".(s:DB_get('dict_show_owner')==1?"TRIM(CAST(procschema AS VARCHAR(15))) || '.' || ":'').
                \ "       CAST(procname AS VARCHAR(40)) AS procschema_procname " .
                \ "  from syscat.procedures " .
                \ " order by ".(s:DB_get('dict_show_owner')==1?"procschema, ":'')."procname" 
                \ )
    return s:DB_DB2_stripHeaderFooter(result)
endfunction

function! s:DB_DB2_getDictionaryView() 
    let result = s:DB_DB2_execSql( 
                \ "select ".(s:DB_get('dict_show_owner')==1?"TRIM(CAST(viewschema AS VARCHAR(15))) || '.' || ":'').
                \ "       CAST(viewname AS VARCHAR(40)) AS viewschema_viewname " .
                \ "  from syscat.views " .
                \ " order by ".(s:DB_get('dict_show_owner')==1?"viewschema, ":'')."viewname" 
                \ )
    return s:DB_DB2_stripHeaderFooter(result)
endfunction 
"}}}
" INGRES exec {{{
function! s:DB_INGRES_execSql(str)
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let terminator = dbext#DB_getWType("cmd_terminator")

    let output = dbext#DB_getWType("cmd_header") 
    " Check if a login_script has been specified
    let output = output.s:DB_getLoginScript(s:DB_get("login_script"))
    let output = output.a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(terminator) . 
                \ '['."\n".' \t]*$'
        let output = output . terminator
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(dbext#DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . 
                \ s:DB_option('', dbext#DB_getWTypeDefault("extra"), ' ') .
                \ s:DB_option('-S ', s:DB_get("dbname"), ' ') .
                \ s:DB_option('', dbext#DB_getWType("cmd_options"), ' ') .
                \ ' < ' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output, "")

    return result
endfunction

function! s:DB_INGRES_describeTable(table_name)
    return s:DB_INGRES_execSql("help " . a:table_name . ";")
endfunction

function! s:DB_INGRES_describeProcedure(procedure_name)
    echo 'Feature not yet available'
    return -1
    " return s:DB_INGRES_execSql("help ".a:procedure_name.";")
endfunction

function! s:DB_INGRES_getListTable(table_prefix)
    echo 'Feature not yet available'
    return -1
endfunction

function! s:DB_INGRES_getListProcedure(proc_prefix)
    echo 'Feature not yet available'
    return -1
endfunction

function! s:DB_INGRES_getListView(view_prefix)
    echo 'Feature not yet available'
    return -1
endfunction 

function! s:DB_INGRES_getListColumn(table_name) 
    echo 'Feature not yet available'
    return -1
endfunction 

function! s:DB_INGRES_stripHeaderFooter(result)
    return
endfunction 

function! s:DB_INGRES_getDictionaryTable() 
    echo 'Feature not yet available'
    return -1
endfunction 

function! s:DB_INGRES_getDictionaryProcedure() 
    echo 'Feature not yet available'
    return -1
endfunction 

function! s:DB_INGRES_getDictionaryView() 
    echo 'Feature not yet available'
    return -1
endfunction 
"}}}
" INTERBASE exec {{{
function! s:DB_INTERBASE_execSql(str)
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let terminator = dbext#DB_getWType("cmd_terminator")

    let output = dbext#DB_getWType("cmd_header") 
    " Check if a login_script has been specified
    let output = output.s:DB_getLoginScript(s:DB_get("login_script"))
    let output = output.a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(terminator) . 
                \ '['."\n".' \t]*$'
        let output = output . terminator
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(dbext#DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . 
                \ s:DB_option('-username ', s:DB_get("user"), ' ') .
                \ s:DB_option('-password ', s:DB_get("passwd"), ' ') .
                \ s:DB_option('', dbext#DB_getWType("cmd_options"), ' ') .
                \ s:DB_option('', dbext#DB_getWTypeDefault("extra"), ' ') .
                \ '-input ' . s:dbext_tempfile .
                \ s:DB_option(' ', s:DB_get("dbname"), '')
    let result = s:DB_runCmd(cmd, output, "")

    return result
endfunction

function! s:DB_INTERBASE_describeTable(table_name)
    return s:DB_INTERBASE_execSql("show table ".a:table_name.";")
endfunction

function! s:DB_INTERBASE_describeProcedure(procedure_name)
    echo 'Feature not yet available'
    return -1
    " return s:DB_INTERBASE_execSql("show procedure ".a:procedure_name.";")
endfunction

function! s:DB_INTERBASE_getListTable(table_prefix)
    echo 'Feature not yet available'
    return -1
endfunction

function! s:DB_INTERBASE_getListProcedure(proc_prefix)
    echo 'Feature not yet available'
    return -1
endfunction

function! s:DB_INTERBASE_getListView(view_prefix)
    echo 'Feature not yet available'
    return -1
endfunction 

function! s:DB_INTERBASE_getListColumn(table_name) 
    echo 'Feature not yet available'
    return -1
endfunction 

function! s:DB_INTERBASE_stripHeaderFooter(result)
    return
endfunction 

function! s:DB_INTERBASE_getDictionaryTable() 
    echo 'Feature not yet available'
    return -1
endfunction 

function! s:DB_INTERBASE_getDictionaryProcedure() 
    echo 'Feature not yet available'
    return -1
endfunction 

function! s:DB_INTERBASE_getDictionaryView() 
    echo 'Feature not yet available'
    return -1
endfunction 
"}}}
" MYSQL exec {{{
function! s:DB_MYSQL_execSql(str)
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let terminator = dbext#DB_getWType("cmd_terminator")

    let output = dbext#DB_getWType("cmd_header") 
    " Check if a login_script has been specified
    let output = output.s:DB_getLoginScript(s:DB_get("login_script"))
    let output = output.a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(terminator) . 
                \ '['."\n".' \t]*$'
        let output = output . terminator
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(dbext#DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . dbext#DB_getWType("cmd_options")
    let cmd = cmd .
                \ s:DB_option(' -u ', s:DB_get("user"), '') .
                \ s:DB_option(' -p',  s:DB_get("passwd"), '') .
                \ s:DB_option(' -h ', s:DB_get("host"), '') .
                \ s:DB_option(' -P ', s:DB_get("port"), '') .
                \ s:DB_option(' -D ', s:DB_get("dbname"), '') .
                \ s:DB_option(' ', dbext#DB_getWTypeDefault("extra"), '') .
                \ ' < ' . s:dbext_tempfile
                " \ s:DB_option(' ', '-t', '') .
    let result = s:DB_runCmd(cmd, output, "")

    return result
endfunction

function! s:DB_MYSQL_describeTable(table_name)
    return s:DB_MYSQL_execSql("describe ".a:table_name)
endfunction

function! s:DB_MYSQL_describeProcedure(procedure_name)
    return s:DB_MYSQL_execSql("describe ".a:procedure_name)
    return result
endfunction

function! s:DB_MYSQL_getListTable(table_prefix)
    let query = "show tables like '" .
                \ a:table_prefix .
                \ "%'" 
    return s:DB_MYSQL_execSql(query)
endfunction

function! s:DB_MYSQL_getListProcedure(proc_prefix)
    if dbext#DB_getWType('version') < '5'
        call s:DB_warningMsg( 'dbext:MySQL does not support procedures' )
        return '-1'
    endif
    let owner   = s:DB_getObjectOwner(a:proc_prefix)
    let object  = s:DB_getObjectName(a:proc_prefix)
    let query = "SELECT specific_name, routine_schema  ".
                \ "  FROM INFORMATION_SCHEMA.ROUTINES " .
                \ " WHERE specific_name  like '".object."%' ".
                \ "   AND routine_schema like '".owner."%' "
    return s:DB_MYSQL_execSql(query)
endfunction

function! s:DB_MYSQL_getListView(view_prefix)
    if dbext#DB_getWType('version') < '5'
        call s:DB_warningMsg( 'dbext:MySQL does not support views' )
        return '-1'
    endif
    let owner   = s:DB_getObjectOwner(a:view_prefix)
    let object  = s:DB_getObjectName(a:view_prefix)
    let query = "SELECT table_name AS view_name, table_schema  ".
                \ "  FROM INFORMATION_SCHEMA.VIEWS " .
                \ " WHERE table_name   like '".object."%' ".
                \ "   AND table_schema like '".owner."%' "
    return s:DB_MYSQL_execSql(query)
endfunction 

function! s:DB_MYSQL_getListColumn(table_name) "{{{
    let result = s:DB_MYSQL_execSql("show columns from ".a:table_name)
    " Strip off header separators ending with a newline
    " let stripped = substitute( result, '+[-]\|+'."[\<C-J>]", '', '' )
    " Strip off separators if using mysqls tabbed output
    " +--------------------+----------------------+------+-----+
    " | name               | char(64)             | NO   | UNI |
    let stripped = substitute( result, '+[-+]\++\n', '', 'g' )
    " Strip off column headers ending with a newline
    let stripped = substitute( stripped, '.\{-}'."[\<C-J>]", '', '' )
    " Strip off all but the column name, if the tabbed output it on the
    " column can begin with a |
    let stripped = substitute( stripped, '\%(|\s*\)\?\(\<\w\+\>\).\{-}'."[\<C-J>]", '\1, ', 'g' )
    " Strip off ending comma
    let stripped = substitute( stripped, ',\s*$', '', '' )
    return stripped
endfunction "}}}

function! s:DB_MYSQL_stripHeaderFooter(result) "{{{
    " Strip off separators if using mysqls tabbed output
    let stripped = substitute( a:result, '+[-+]\++\n', '', 'g' )
    " The mysql utility does not return row counts like many 
    " of the other databases
    let g:dbext_rows_affected = ''
    " Strip off header separators ending with a newline
    let stripped = substitute( stripped, '+[-]\|.\{-}'."[\<C-V>\<C-J>]", '', '' )
    " Strip off column headers ending with a newline
    let stripped = substitute( stripped, '|.*Tables_in.*'."[\<C-V>\<C-J>]", '', '' )
    " Strip off preceeding and ending |s
    let stripped = substitute( stripped, '|', '', 'g' )
    " Strip off trailing spaces
    " let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*\(\n\)', '\1\2', '' )
    return stripped
endfunction "}}}

function! s:DB_MYSQL_getDictionaryTable() "{{{
    if dbext#DB_getWType('version') < '5'
        let result = s:DB_MYSQL_getListTable('')
    else
        let query = "SELECT ".(s:DB_get('dict_show_owner')==1?"CONCAT_WS('.', TABLE_SCHEMA, TABLE_NAME)":"TABLE_NAME").
                    \ "  FROM INFORMATION_SCHEMA.TABLES " .
                    \ " WHERE TABLE_TYPE  = 'BASE TABLE' ".
                    \ " ORDER BY ".(s:DB_get('dict_show_owner')==1?"TABLE_SCHEMA, ":'')."TABLE_NAME"
        let result = s:DB_MYSQL_execSql(query)
    endif
    return s:DB_MYSQL_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_MYSQL_getDictionaryProcedure() "{{{
    if dbext#DB_getWType('version') < '5'
        call s:DB_warningMsg( 'dbext:MySQL does not support procedures' )
        return '-1'
    endif
    let query = "SELECT ".(s:DB_get('dict_show_owner')==1?"CONCAT_WS('.', ROUTINE_SCHEMA, SPECIFIC_NAME)":"SPECIFIC_NAME").
                \ "  FROM INFORMATION_SCHEMA.ROUTINES " .
                \ " ORDER BY ".(s:DB_get('dict_show_owner')==1?"ROUTINE_SCHEMA, ":'')."SPECIFIC_NAME"
    let result = s:DB_MYSQL_execSql(query)
    return s:DB_MYSQL_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_MYSQL_getDictionaryView() "{{{
    if dbext#DB_getWType('version') < '5'
        call s:DB_warningMsg( 'dbext:MySQL does not support views' )
        return '-1'
    endif
    let query = "SELECT ".(s:DB_get('dict_show_owner')==1?"CONCAT_WS('.', TABLE_SCHEMA, TABLE_NAME)":"TABLE_NAME").
                \ "  FROM INFORMATION_SCHEMA.VIEWS " .
                \ " ORDER BY ".(s:DB_get('dict_show_owner')==1?"TABLE_SCHEMA, ":'')."TABLE_NAME"
    let result = s:DB_MYSQL_execSql(query)
    return s:DB_MYSQL_stripHeaderFooter(result)
endfunction "}}}
"}}}
" SQLITE exec {{{
function! s:DB_SQLITE_execSql(str)

    if s:DB_get("dbname") == ""
        call s:DB_warningMsg("dbext:You must specify a database name/file")
        return -1
    endif

    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let terminator = dbext#DB_getWType("cmd_terminator")

    let output = dbext#DB_getWType("cmd_header") 
    " Check if a login_script has been specified
    let output = output.s:DB_getLoginScript(s:DB_get("login_script"))
    let output = output.a:str
    " Only include a command terminator if one has not already
    " been added, since builtin commands beginning with a "."
    " cannot be ended with a ;, check the last line in the command
    " to determine if it is a . command.
    " Some sample . commands:
    "    .tables
    "    .schema
    "    .mode csv
    "    .headers on
    let last_line = substitute(a:str, '.*\n\(.*\)\n', '\1', '')

    " If it does not start with a .
    " and it does not end with a ;
    if last_line !~ '^\.' && 
                \ last_line !~ terminator . '['."\n".' \t]*$'
        let output = output . terminator
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(dbext#DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . dbext#DB_getWType("cmd_options")
    let cmd = cmd .
                \ s:DB_option(' ', dbext#DB_getWTypeDefault("extra"), '') .
                \ s:DB_option(' ', s:DB_get("dbname"), '') .
                \ ' < ' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output, "")

    return result
endfunction

function! s:DB_SQLITE_describeTable(table_name)
    let query =   ".schema " . a:table_name
    return s:DB_SQLITE_execSql(query)
endfunction

function! s:DB_SQLITE_describeProcedure(procedure_name)
    echo 'Feature not yet available'
    return -1
endfunction

function! s:DB_SQLITE_stripHeaderFooter(result)
    " Strip off column headers ending with a newline
    let stripped = a:result
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-J>]", '', '' )
    " " Strip off query statistics
    " let stripped = substitute( stripped, '(\d\+ rows\_.*', '', '' )
    " " Strip off trailing spaces
    " let stripped = substitute( stripped, '\(\<\w\+\>\)\s*\(\n\)', '\1\2', '' )
    return stripped
endfunction

function! s:DB_SQLITE_getListColumn(table_name)
    let l:prev_use_result_buffer = s:DB_get('use_result_buffer')
    call s:DB_set('use_result_buffer', 0)
    
    let result = s:DB_SQLITE_describeTable(a:table_name)
    
    call s:DB_set('use_result_buffer', l:prev_use_result_buffer)
    " \<C-J> = Enter
    " Remove all newlines
    let result = substitute( result, '[ '."\<C-J>".']', ' ', 'g' )
    " Strip off beginning create table command
    let result = substitute( result, '^\s*create.*table\s\+'.a:table_name.'\s*(\s*', '', '' )
    " Strip off trailing part of create table statement
    let result = substitute( result, 'primary\s\+key\s*(.*', '', '' )
    " Strip off trailing part of create table statement
    let result = substitute( result, 'unique\s*(.*', '', '' )
    " Strip off trailing part of create table statement
    let result = substitute( result, '\s*)\s*;', ',', '' )
    " Strip off data types
    let result = substitute( result, '\s*\(\w\+\).\{-}\([,]\+\|$\)', '\1, ', 'g' )
    " Strip off trailing ,
    let result = substitute( result, ',\s*$', "\n", '' )
    " Strip off all following spaces and newlines
    " let result = substitute( result, '\w\>\zs[ '."\<C-J>".']*$', '\1', '' )

    return s:DB_SQLITE_stripHeaderFooter(result)
endfunction 

function! s:DB_SQLITE_getListTable(table_prefix)
    let query  = ".tables " . a:table_prefix
    let l:prev_use_result_buffer = s:DB_get('use_result_buffer')
    call s:DB_set('use_result_buffer', 0)
    
    let result = s:DB_SQLITE_execSql(query)
    
    call s:DB_set('use_result_buffer', l:prev_use_result_buffer)

    let result = "Tables\n------\n".
                \ substitute( result, '\w\zs\s\+\ze\w', '\n', 'g' )

    call s:DB_addToResultBuffer(result, "clear")

    return result
endfunction

function! s:DB_SQLITE_getListProcedure(proc_prefix)
    echo 'Feature not yet available'
    return -1
endfunction

function! s:DB_SQLITE_getListView(view_prefix)
    echo 'Feature not yet available'
    return -1
endfunction 

function! s:DB_SQLITE_getDictionaryTable()
    let result = s:DB_SQLITE_getListTable('')
    return s:DB_SQLITE_stripHeaderFooter(result)
endfunction 

function! s:DB_SQLITE_getDictionaryProcedure() 
    echo 'Feature not yet available'
    return -1
endfunction 

function! s:DB_SQLITE_getDictionaryView()
    echo 'Feature not yet available'
    return -1
endfunction 
"}}}
" ORA exec {{{
function! s:DB_ORA_execSql(str)
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let terminator = dbext#DB_getWType("cmd_terminator")

    let output = dbext#DB_getWType("cmd_header") 
    " Check if a login_script has been specified
    let output = output.s:DB_getLoginScript(s:DB_get("login_script"))
    let output = output.a:str
    " Only include a command terminator if one has not already
    " been added
    " Added quit to the end of the command to exit SQLPLUS
    if output !~ s:DB_escapeStr(terminator) . 
                \ '['."\n".' \t]*$'
        let output = output . "\n" . terminator
     endif
 
    " Added quit to the end of the command to exit SQLPLUS
    let output = output . "\nquit"

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(dbext#DB_getWType("bin"))

    let cmd = dbext_bin .  
                \ ' ' . dbext#DB_getWType("cmd_options") .
                \ s:DB_option(" '", s:DB_get("user"), '') .
                \ s:DB_option('/', s:DB_get("passwd"), '') .
                \ s:DB_option('@', s:DB_get("srvname"), '') .
                \ s:DB_option(' ', dbext#DB_getWTypeDefault("extra"), '') .
                \ '" @' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output, "")

    return result
endfunction

function! s:DB_ORA_describeTable(table_name)
    return s:DB_ORA_execSql("set linesize 100\ndesc " . a:table_name)
endfunction

function! s:DB_ORA_describeProcedure(procedure_name)
    return s:DB_ORA_execSql("set linesize 100\ndesc " . a:procedure_name)
endfunction

function! s:DB_ORA_getListTable(table_prefix)
    let owner      = toupper(s:DB_getObjectOwner(a:table_prefix))
    let table_name = toupper(s:DB_getObjectName(a:table_prefix))
    let query =   "select table_name, owner, tablespace_name ".
                \ "  from ALL_ALL_TABLES ".
                \ " where table_name LIKE '".table_name."%' "
    if strlen(owner) > 0
        let query = query .
                    \ "   and owner = '".owner."' "
    endif
    let query = query .
                \ " order by table_name"
    return s:DB_ORA_execSql( query )
endfunction

function! s:DB_ORA_getListProcedure(proc_prefix)
    let owner      = toupper(s:DB_getObjectOwner(a:proc_prefix))
    let obj_name   = toupper(s:DB_getObjectName(a:proc_prefix))
    let pkg_name   = s:DB_getObjectOwner(obj_name)
    if !empty(pkg_name)
        let obj_name = s:DB_getObjectName(obj_name)
    endif

    if !empty(owner)
        if !empty(pkg_name) " schema.package.procedure
            let query =   "select procedure_name object_name, owner ||'.'|| object_name owner ".
                        \ "  from all_procedures ".
                        \ " where object_type = 'PACKAGE' ".
                        \ "   and procedure_name LIKE '".obj_name."%' ".
                        \ "   and owner = '".owner."' and object_name = '".pkg_name."'"
        else " schema.procedureORpackage or package.procedure
            let query =   "select object_name, owner ".
                        \ "  from all_objects ".
                        \ " where object_type IN ('PROCEDURE', 'PACKAGE', 'FUNCTION') ".
                        \ "   and object_name LIKE '".obj_name."%' ".
                        \ "   and owner = '".owner."'".
                        \ " UNION ALL ".
                        \ "select procedure_name, object_name ".
                        \ "  from all_procedures ".
                        \ " where object_type = 'PACKAGE' ".
                        \ "   and object_name = '".owner."'".
                        \ "   and procedure_name LIKE '".obj_name."%'"
        endif
    else " just a name
        let query =   "select object_name, owner ".
                    \ "  from all_objects ".
                    \ " where object_type IN ('PROCEDURE', 'PACKAGE', 'FUNCTION') " .
                    \ "   and object_name LIKE '".obj_name."%' "
    endif

    let query .= " order by 1"
    return s:DB_ORA_execSql( query )
endfunction

function! s:DB_ORA_getListView(view_prefix)
    let owner      = toupper(s:DB_getObjectOwner(a:view_prefix))
    let obj_name   = toupper(s:DB_getObjectName(a:view_prefix))
    let query =   "select view_name, owner ".
                \ "  from ALL_VIEWS ".
                \ " where view_name LIKE '".obj_name."%' "
    if strlen(owner) > 0
        let query = query .
                    \ "   and owner = '".owner."' "
    endif
    let query .= " order by view_name"
    return s:DB_ORA_execSql( query )
endfunction 

function! s:DB_ORA_getListColumn(table_name) "{{{
    let owner      = toupper(s:DB_getObjectOwner(a:table_name))
    let table_name = toupper(s:DB_getObjectName(a:table_name))
    let query =   "select column_name     ".
                \ "  from ALL_TAB_COLUMNS ".
                \ " where table_name = '".table_name."' "
    if !empty(owner)
        let query .= "   and owner = '".owner."' "
    endif
    let query .= " order by column_id"
    let result = s:DB_ORA_execSql( query )
    return s:DB_ORA_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_ORA_stripHeaderFooter(result) "{{{
    " Strip off column headers ending with a newline
    let stripped = substitute( a:result, '^\_.\{-}[- ]\+\n', '', 'g' )
    let g:dbext_rows_affected = matchstr(stripped, '\zs\d\+\ze\s\+row')
    " Strip off query statistics
    let stripped = substitute( stripped, '\d\+ rows\_.*', '', '' )
    " Strip off no rows selected
    let stripped = substitute( stripped, 'no rows selected\_.*', '', '' )
    " Strip off trailing spaces
    " let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*\(\n\)', '\1\2', '' )
    return stripped
endfunction "}}}

function! s:DB_ORA_getDictionaryTable() "{{{
    let result = s:DB_ORA_execSql(
                \ "set pagesize 0\n".
                \ "select ".(s:DB_get('dict_show_owner')==1?"owner||'.'||":'')."table_name" .
                \ "  from ALL_ALL_TABLES " .
                \ " order by ".(s:DB_get('dict_show_owner')==1?"owner, ":'')."table_name  "
                \ )
    return s:DB_ORA_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_ORA_getDictionaryProcedure() "{{{
    let query = "set pagesize 0\n".
                \"select ".(s:DB_get('dict_show_owner')==1?"owner||'.'||":'')."object_name                          " .
                \ "  from all_objects                          " .
                \ " where object_type IN                       " .
                \ "       ('PROCEDURE', 'PACKAGE', 'FUNCTION') " .
                \ " UNION ALL " .
                \ "select ".(s:DB_get('dict_show_owner')==1?"owner||'.'||object_name||'.'||":'')."procedure_name            " .
                \ "  from all_procedures                       " .
                \ " where object_type = 'PACKAGE' and procedure_name is not null "
    if s:DB_get('dict_show_owner')==1
        let query .= " UNION ALL " .
                \ "select object_name||'.'||procedure_name     " .
                \ "  from all_procedures                       " .
                \ " where object_type = 'PACKAGE' and procedure_name is not null "
    endif
    let query .= " order by 1"
    let result = s:DB_ORA_execSql(query)
    return s:DB_ORA_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_ORA_getDictionaryView() "{{{
    let result = s:DB_ORA_execSql(
                \ "set pagesize 0\n".
                \ "select ".(s:DB_get('dict_show_owner')==1?"owner||'.'||":'')."view_name    " .
                \ "  from ALL_VIEWS    " .
                \ " order by ".(s:DB_get('dict_show_owner')==1?"owner, ":'')."view_name "
                \ )
    return s:DB_ORA_stripHeaderFooter(result)
endfunction "}}}
"}}}
" PGSQL exec {{{
function! s:DB_PGSQL_check_pgpass()
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let filename = dbext#DB_getWType("pgpass")

    if !filereadable(expand(filename))
        call s:DB_warningMsg( 
                    \ "dbext:PostgreSQL requires a '".
                    \ dbext#DB_getWType("pgpass").
                    \ "' file in order to authenticate.  ".
                    \ 'This file is missing.  '.
                    \ "The binary '".
                    \ dbext#DB_getWType("bin").
                    \ "' does not accept commandline passwords."
                    \ )
        return -1
    endif

    return
endfunction

function! s:DB_PGSQL_execSql(str)
    if s:DB_PGSQL_check_pgpass() == -1 
        return -1
    endif

    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let terminator = dbext#DB_getWType("cmd_terminator")

    let output = dbext#DB_getWType("cmd_header") 
    " Check if a login_script has been specified
    let output = output.s:DB_getLoginScript(s:DB_get("login_script"))
    let output = output.a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(terminator) . 
                \ '['."\n".' \t]*$'
        let output = output . terminator
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(dbext#DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . 
                \ s:DB_option('', dbext#DB_getWType("cmd_options"), ' ') .
                \ s:DB_option('-d ', s:DB_get("dbname"), ' ') .
                \ s:DB_option('-U ', s:DB_get("user"), ' ') .
                \ s:DB_option('-h ', s:DB_get("host"), ' ') .
                \ s:DB_option('-p ', s:DB_get("port"), ' ') .
                \ s:DB_option(' ', dbext#DB_getWTypeDefault("extra"), '') .
                \ ' -q -f ' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output, "")

    return result
endfunction

function! s:DB_PGSQL_describeTable(table_name)
    return s:DB_PGSQL_execSql('\d ' . a:table_name)
endfunction

function! s:DB_PGSQL_describeProcedure(procedure_name)
    let owner      = s:DB_getObjectOwner(a:procedure_name)
    let proc_name  = s:DB_getObjectName(a:procedure_name)
    let query =   "SELECT p.* ".
                \ "  FROM pg_proc p, pg_type t, pg_language l " .
                \ " WHERE p.proargtypes = t.oid " .
                \ "   AND p.prolang = t.oid " .
                \ "   AND p.proname = '" . proc_name . "'"
    " let query =   "SELECT t.typname, t.typdefault, t.typinput " .
    "             \ "     , t.typoutput, l.lanname " .
    "             \ "  FROM pg_proc p, pg_type t, pg_language l " .
    "             \ " WHERE p.proargtypes = t.oid " .
    "             \ "   AND p.prolang = t.oid " .
    "             \ "   AND p.proname = '" . proc_name . "'"
 
    if strlen(owner) > 0
        let query = query .
                    \ "   AND pg_get_userbyid(p.proowner) = '".owner."' "
    endif
    let query = query .
                \ " ORDER BY p.pronargs;            "
    return s:DB_PGSQL_execSql( query )
endfunction

function! s:DB_PGSQL_getListTable(table_prefix)
    let owner      = s:DB_getObjectOwner(a:table_prefix)
    let table_name = s:DB_getObjectName(a:table_prefix)
    let query = "select tablename, tableowner " .
                \ " from pg_tables " .
                \ "where tableowner != 'pg_catalog' " .
                \ "  and tableowner like '" . owner . "%' " .
                \ "  and tablename  like '" . table_name . "%' " .
                \ "order by tablename"
    return s:DB_PGSQL_execSql(query)
endfunction

function! s:DB_PGSQL_getListProcedure(proc_prefix)
    let owner   = s:DB_getObjectOwner(a:proc_prefix)
    let object  = s:DB_getObjectName(a:proc_prefix)
    let query = "  SELECT p.proname, pg_get_userbyid(u.usesysid) " .
                \ "  FROM pg_proc p, pg_user u " .
                \ " WHERE p.proowner = u.usesysid " .
                \ "   AND u.usename  like '" . owner . "%' " .
                \ "   AND p.proname  like '" . object . "%' " .
                \ " ORDER BY p.proname"
    return s:DB_PGSQL_execSql(query)
endfunction

function! s:DB_PGSQL_getListView(view_prefix)
    let owner      = s:DB_getObjectOwner(a:view_prefix)
    let view_name  = s:DB_getObjectName(a:view_prefix)
    let query = "select viewname, viewowner " .
                \ " from pg_views " .
                \ "where viewowner != 'pg_catalog' " .
                \ "  and viewowner like '" . owner ."%' " .
                \ "  and viewname  like '" . view_name . "%' " .
                \ "order by viewname"
    return s:DB_PGSQL_execSql(query)
endfunction 

function! s:DB_PGSQL_getListColumn(table_name) 
    let owner      = s:DB_getObjectOwner(a:table_name)
    let table_name = s:DB_getObjectName(a:table_name)
    let query =   "SELECT a.attname                  " .
                \ "  FROM pg_class c, pg_attribute a " .
                \ " WHERE c.relfilenode = a.attrelid " .
                \ "   AND a.attnum > 0               " .
                \ "   AND c.relname = '" . table_name . "'"
 
    if strlen(owner) > 0
        let query = query .
                    \ "   AND pg_get_userbyid(c.relowner) = '".owner."' "
    endif
    let query = query .
                \ " ORDER BY a.attnum;            "
    let result = s:DB_PGSQL_execSql( query )
    return s:DB_PGSQL_stripHeaderFooter(result)
endfunction 

function! s:DB_PGSQL_stripHeaderFooter(result)
    " Strip off column headers ending with a newline
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-J>]", '', '' )
    let g:dbext_rows_affected = matchstr(stripped, '(\zs\d\+\ze rows')
    " Strip off query statistics
    let stripped = substitute( stripped, '(\d\+ rows\_.*', '', '' )
    " Strip off trailing spaces
    " let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*\(\n\)', '\1\2', '' )
    return stripped
endfunction 

function! s:DB_PGSQL_getDictionaryTable() 
    let result = s:DB_PGSQL_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"tableowner||'.'||":'')."tablename " .
                \ " from pg_tables " .
                \ "where tableowner != 'pg_catalog' " .
                \ "order by ".(s:DB_get('dict_show_owner')==1?"tableowner, ":'')."tablename"
                \ )
    return s:DB_PGSQL_stripHeaderFooter(result)
endfunction 

function! s:DB_PGSQL_getDictionaryProcedure() 
    let result = s:DB_PGSQL_execSql(
                \ "SELECT p.proname " .
                \ "  FROM pg_proc p " .
                \ " ORDER BY p.proname "
                \ )
    return s:DB_PGSQL_stripHeaderFooter(result)
endfunction 

function! s:DB_PGSQL_getDictionaryView() 
    let result = s:DB_PGSQL_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"viewowner||'.'||":'')."viewname " .
                \ "  from pg_views " .
                \ " where viewowner != 'pg_catalog' " .
                \ " order by ".(s:DB_get('dict_show_owner')==1?"viewowner, ":'')."viewname"
                \ )
    return s:DB_PGSQL_stripHeaderFooter(result)
endfunction 
"}}}
" RDB exec {{{
function! s:DB_RDB_describeProcedure(procedure_name) "{{{
    return s:DB_RDB_execSql("show procedure " . a:procedure_name)
endfunction "}}}
function! s:DB_RDB_describeTable(table_name) "{{{
    return s:DB_RDB_execSql("show table " . a:table_name)
endfunction "}}}
function! s:DB_RDB_execSql(str) "{{{
    let host    = s:DB_get("host")
    let srvname = s:DB_get("srvname")
    let user    = s:DB_get("user")
    let passwd  = s:DB_get("passwd")
    let sup     = ''

    if host != ''
        let srvname = host
    endif
    if srvname != ''
        if user != ''
            if passwd != ''
                let sup = srvname . '"' . user . ' ' . passwd . '"::'
            else
                let sup = srvname . '"' . user . '"::'
            endif
        else
            let sup = srvname . '::'
        endif
    endif
                
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let terminator = dbext#DB_getWType("cmd_terminator")

    let output = s:DB_option( 
                \     'attach ''filename ', 
                \     sup . s:DB_get("dbname"), 
                \     '''' 
                \ )  . 
                \ terminator .
                \ dbext#DB_getWType("cmd_header")
    " Check if a login_script has been specified
    let output = output.s:DB_getLoginScript(s:DB_get("login_script"))
    let output = output.a:str
    " Only include a command terminator if one has not already
    " been added
    " Added quit to the end of the command to exit SQLPLUS
    if output !~ s:DB_escapeStr(terminator) . 
                \ '['."\n".' \t]*$'
        let output = output . terminator
     endif
 
    " Added quit to the end of the command to exit SQLPLUS
    let output = output . "\nquit".terminator

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(dbext#DB_getWType("bin"))

    let cmd = dbext_bin . ' @' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output, "")

    return result
endfunction "}}}
function! s:DB_RDB_getDictionaryProcedure() "{{{
    let result = s:DB_RDB_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"decode(bitstring (RDB$FLAGS from 20 for 1),0,trim(RDB$ROUTINE_CREATOR),'SYS')||'.'||":'').
                    \ "RDB$ROUTINE_NAME ".
                  \ "from RDB$ROUTINES ".
                  \ "where bitstring (RDB$FLAGS from 20 for 1) = 0 ".
                  \ "order by RDB$ROUTINE_NAME "
                \ )
    return s:DB_RDB_stripHeaderFooter(result)
endfunction "}}}
function! s:DB_RDB_getDictionaryTable() "{{{
    let result = s:DB_RDB_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"decode(RDB$SYSTEM_FLAG,0,trim(RDB$RELATION_CREATOR),'SYS')||'.'||":'').
                    \ "RDB$RELATION_NAME ".
                  \ "from RDB$RELATIONS ".
                  \ "where RDB$VIEW_BLR is null " .
                  \ "order by RDB$RELATION_NAME "
                \ )
    return s:DB_RDB_stripHeaderFooter(result)
endfunction "}}}
function! s:DB_RDB_getDictionaryView() "{{{
    let result = s:DB_RDB_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"decode(RDB$SYSTEM_FLAG,0,trim(RDB$RELATION_CREATOR),'SYS')||'.'||":'').
                    \ "RDB$RELATION_NAME " .
                  \ "from RDB$RELATIONS " .
                  \ "where RDB$VIEW_BLR is not null " .
                  \ "order by RDB$RELATION_NAME "
                \ )
    return s:DB_RDB_stripHeaderFooter(result)
endfunction "}}}
function! s:DB_RDB_getListColumn(table_name) "{{{
    let owner      = toupper(s:DB_getObjectOwner(a:table_name))
    let table_name = toupper(s:DB_getObjectName(a:table_name))
    let query =   "select RDB$FIELD_NAME \"\"".
                  \ "from RDB$RELATION_FIELDS RF inner join RDB$RELATIONS R using (RDB$RELATION_NAME) ".
                  \ "where RDB$RELATION_NAME = '".table_name."' "
    if strlen(owner) > 0
        let query = query .
                    \ "and decode(R.RDB$SYSTEM_FLAG,0,R.RDB$RELATION_CREATOR,'SYS') = '".owner."' "
    endif
    let query = query .
                  \ "order by RF.RDB$FIELD_POSITION "
    let result = s:DB_RDB_execSql( query )
    return s:DB_RDB_stripHeaderFooter(result)
endfunction "}}}
function! s:DB_RDB_getListProcedure(proc_prefix) "{{{
    let owner      = toupper(s:DB_getObjectOwner(a:proc_prefix))
    let obj_name   = toupper(s:DB_getObjectName(a:proc_prefix))
"        RDB$ROUTINES.RDB$FLAGS "{{{
"           Represents flags for RDB$ROUTINES system table.
"
"           Bit
"           Position   Description
"
"           0          Routine is a function. (Call returns a result.)
"           1          Routine is not valid. (Invalidated by a metadata
"                      change.)
"           2          The function is not deterministic (that is, the routine
"                      is variant). A subsequent invocation of the routine
"                      with identical parameters may return different results.
"           3          Routine can change the transaction state.
"           4          Routine is in a secured shareable image.
"           5          Reserved for future use.
"           6          Routine is not valid. (Invalidated by a metadata change
"                      to the object upon which this routine depends. This
"                      dependency is a language semantics dependency.)
"           7          Reserved for future use.
"           8          External function returns NULL when called with any
"                      NULL parameter.
"           9          Routine has been analyzed (used for trigger dependency
"                      tracking).
"           10         Routine inserts rows.
"           11         Routine modifies rows.
"           12         Routine deletes rows.
"           13         Routine selects rows.
"           14         Routine calls other routines.
"           15         Reserved for future use.
"           16         Routine created with USAGE IS LOCAL clause.
"           17         Reserved for future use.
"           18         Reserved for future use.
"           19         Routine is a SYSTEM routine.
"           20         Routine generated by Oracle Rdb.
"                      Other bits are reserved for future use. "}}}

    let query =   "select RDB$ROUTINE_NAME, ".
                    \ "decode(bitstring (RDB$FLAGS from 20 for 1),0,RDB$ROUTINE_CREATOR,'SYS') RDB$ROUTINE_CREATOR ".
                  \ "from RDB$ROUTINES ".
                  \ "where RDB$ROUTINE_NAME LIKE '".obj_name."%' " 
    if strlen(owner) > 0
        let query = query .
                    \ "and decode(bitstring (RDB$FLAGS from 20 for 1),0,RDB$ROUTINE_CREATOR,'SYS') = '".owner."' "
    endif
    let query = query .
                \ " order by RDB$ROUTINE_NAME"
    return s:DB_RDB_execSql( query )
endfunction "}}}
function! s:DB_RDB_getListTable(table_prefix) "{{{
    let owner      = toupper(s:DB_getObjectOwner(a:table_prefix))
    let table_name = toupper(s:DB_getObjectName(a:table_prefix))
    let query =   "select RDB$RELATION_NAME, decode(RDB$SYSTEM_FLAG,0,RDB$RELATION_CREATOR,'SYS'), 'RDB_TABLESPACE' ".
                  \ "from RDB$RELATIONS ".
                  \ "where RDB$RELATION_NAME LIKE '".table_name."%' "
    if strlen(owner) > 0
        let query = query .
                    \ "and decode(RDB$SYSTEM_FLAG,0,RDB$RELATION_CREATOR,'SYS') = '".owner."' "
    endif
    let query = query .
                  \ "order by RDB$RELATION_NAME"
    return s:DB_RDB_execSql( query )
endfunction "}}}
function! s:DB_RDB_getListView(view_prefix) "{{{
    let owner      = toupper(s:DB_getObjectOwner(a:view_prefix))
    let obj_name   = toupper(s:DB_getObjectName(a:view_prefix))
    let query =   "select RDB$RELATION_NAME, decode(RDB$SYSTEM_FLAG,0,RDB$RELATION_CREATOR,'SYS') ".
                  \ "from RDB$RELATIONS ".
                  \ "where RDB$RELATION_NAME LIKE '".obj_name."%' " .
                    \ "and RDB$VIEW_BLR is not null "
    if strlen(owner) > 0
        let query = query .
                    \ "and decode(RDB$SYSTEM_FLAG,0,RDB$RELATION_CREATOR,'SYS') = '".owner."' "
    endif
    let query = query .
                  \ "order by RDB$RELATION_NAME"
    return s:DB_RDB_execSql( query )
endfunction "}}}
function! s:DB_RDB_stripHeaderFooter(result) "{{{
    " Strip off column headers ending with a newline
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-J>]", '', '' )
    let g:dbext_rows_affected = matchstr(stripped, '\zs\d\+\ze\s\+row')
    " Strip off query statistics
    let stripped = substitute( stripped, '\d\+ rows\_.*', '', '' )
    " Strip off no rows selected
    let stripped = substitute( stripped, 'no rows selected\_.*', '', '' )
    " Strip off trailing spaces
    " let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*\(\n\)', '\1\2', '' )
    return stripped
endfunction "}}}
"}}}
" SQLSRV exec {{{
function! s:DB_SQLSRV_execSql(str)
    let terminator = dbext#DB_getWType("cmd_terminator")

    let output = dbext#DB_getWType("cmd_header") 
    " Check if a login_script has been specified
    let output = output.s:DB_getLoginScript(s:DB_get("login_script"))
    let output = output.a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(terminator) . 
                \ '['."\n".' \t]*$'
        let output = output . terminator
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(dbext#DB_getWType("bin"))

    let cmd = dbext_bin . ' ' . dbext#DB_getWType("cmd_options")

    if has("win32") && s:DB_get("integratedlogin") == 1
        let cmd = cmd .  ' -E'
    else
        let cmd = cmd . ' -U ' .  s:DB_get("user") .
                \ ' -P' . s:DB_get("passwd") 
    endif

    let cmd = cmd . 
                \ s:DB_option(' -H ', s:DB_get("host"), ' ') .
                \ s:DB_option(' -S ', s:DB_get("srvname"), ' ') .
                \ s:DB_option(' -d ', s:DB_get("dbname"), ' ') .
                \ s:DB_option(' ', dbext#DB_getWTypeDefault("extra"), '') .
                \ ' -i ' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output, "")

    return result
endfunction

function! s:DB_SQLSRV_describeTable(table_name)
    return s:DB_SQLSRV_execSql("exec sp_help ".a:table_name)
endfunction

function! s:DB_SQLSRV_describeProcedure(procedure_name)
    return s:DB_SQLSRV_execSql("exec sp_help ".a:procedure_name)
endfunction

function! s:DB_SQLSRV_stripHeaderFooter(result)
    " Strip off column headers ending with a newline
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-J>]", '', '' )
    let g:dbext_rows_affected = matchstr(stripped, '(\zs\d\+\ze\s\+row')
    " Strip off query statistics
    let stripped = substitute( stripped, '(\d\+ rows\_.*', '', '' )
    " Strip off trailing spaces
    " let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
    " let stripped = substitute( stripped, '^\s*\(.\{-}\)[ \t\r\n]*$', '\1\n', '' )
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*\(\n\)', '\1\2', '' )
    return stripped
endfunction

function! s:DB_SQLSRV_getListColumn(table_name)
    let owner      = s:DB_getObjectOwner(a:table_name)
    let table_name = s:DB_getObjectName(a:table_name)
    let query =   "select convert(varchar,c.name) ".
                \ "  from sysobjects o, sysusers u, syscolumns c ".
                \ " where o.uid=u.uid ".
                \ "   and o.id=c.id ".
                \ "   and o.xtype='U' ".
                \ "   and o.name = '".table_name."' "
    if strlen(owner) > 0
        let query = query .
                    \ "   and u.name = '".owner."' "
    endif
    let query = query .
                \ " order by c.colid"
    let result = s:DB_SQLSRV_execSql( query )
    return s:DB_SQLSRV_stripHeaderFooter(result)
endfunction 

function! s:DB_SQLSRV_getListTable(table_prefix)
    return s:DB_SQLSRV_execSql(
                \ "select convert(varchar,o.name), convert(varchar,u.name) ".
                \ "  from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid ".
                \ "   and o.xtype='U' ".
                \ "   and o.name like '".a:table_prefix."%' ".
                \ " order by o.name"
                \ )
endfunction

function! s:DB_SQLSRV_getListProcedure(proc_prefix)
    return s:DB_SQLSRV_execSql(
                \ "select convert(varchar,o.name), convert(varchar,u.name) ".
                \ "  from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid ".
                \ "   and o.xtype='P' ".
                \ "   and o.name like '".a:proc_prefix."%' ".
                \ " order by o.name"
                \ )
endfunction

function! s:DB_SQLSRV_getListView(view_prefix)
    return s:DB_SQLSRV_execSql(
                \ "select convert(varchar,o.name), convert(varchar,u.name) ".
                \ "  from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid ".
                \ "   and o.xtype='V' ".
                \ "   and o.name like '".a:view_prefix."%' ".
                \ " order by o.name"
                \ )
endfunction 
function! s:DB_SQLSRV_getDictionaryTable() "{{{
    let result = s:DB_SQLSRV_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"convert(varchar,u.name)+'.'+":'').
                \ "       convert(varchar,o.name) ".
                \ "  from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid ".
                \ "   and o.xtype='U' ".
                \ " order by ".(s:DB_get('dict_show_owner')==1?"convert(varchar,u.name), ":'')."o.name"
                \ )
    return s:DB_SQLSRV_stripHeaderFooter(result)
endfunction "}}}
function! s:DB_SQLSRV_getDictionaryProcedure() "{{{
    let result = s:DB_SQLSRV_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"convert(varchar,u.name)+'.'+":'').
                \ "       convert(varchar,o.name) ".
                \ "  from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid ".
                \ "   and o.xtype='P' ".
                \ " order by ".(s:DB_get('dict_show_owner')==1?"convert(varchar,u.name), ":'')."o.name"
                \ )
    return s:DB_SQLSRV_stripHeaderFooter(result)
endfunction "}}}
function! s:DB_SQLSRV_getDictionaryView() "{{{
    let result = s:DB_SQLSRV_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"convert(varchar,u.name)+'.'+":'').
                \ "       convert(varchar,o.name) ".
                \ "  from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid ".
                \ "   and o.xtype='V' ".
                \ " order by ".(s:DB_get('dict_show_owner')==1?"convert(varchar,u.name), ":'')."o.name"
                \ )
    return s:DB_SQLSRV_stripHeaderFooter(result)
endfunction "}}}
"}}}
" FIREBIRD exec {{{
function! s:DB_FIREBIRD_execSql(str)
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let terminator = dbext#DB_getWType("cmd_terminator")

    let output = dbext#DB_getWType("cmd_header") 
    " Check if a login_script has been specified
    let output = output.s:DB_getLoginScript(s:DB_get("login_script"))
    let output = output.a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(terminator) . 
                \ '['."\n".' \t]*$'
        let output = output . terminator
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(dbext#DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . dbext#DB_getWType("cmd_options")
    let cmd = cmd .
                \ s:DB_option(' -u ', s:DB_get("user"), '') .
                \ s:DB_option(' -p ',  s:DB_get("passwd"), '') .
                \ s:DB_option(' ', s:DB_get("dbname"), '') .
                \ s:DB_option(' ', dbext#DB_getWTypeDefault("extra"), '') .
                \ ' < ' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output, "")

    return result
endfunction

function! s:DB_FIREBIRD_describeTable(table_name)
    return s:DB_FIREBIRD_execSql("show tables ".a:table_name)
endfunction

function! s:DB_FIREBIRD_describeProcedure(procedure_name)
    return s:DB_FIREBIRD_execSql("show procedure ".a:procedure_name)
    return result
endfunction

function! s:DB_FIREBIRD_getListTable(table_prefix)
    let query = "SELECT RDB$RELATION_NAME ".
                \" FROM RDB$RELATIONS ".
                \"WHERE RDB$SYSTEM_FLAG=0 ".
                \"  AND RDB$RELATION_NAME LIKE '".a:table_prefix."%'".
                \"ORDER BY RDB$RELATION_NAME "
    return s:DB_FIREBIRD_execSql(query)
endfunction

function! s:DB_FIREBIRD_getListProcedure(proc_prefix)
    let owner   = s:DB_getObjectOwner(a:proc_prefix)
    let object  = s:DB_getObjectName(a:proc_prefix)
    let query = "SELECT DISTINCT RDB$PROCEDURE_NAME ".
                \" FROM RDB$PROCEDURES ".
                \"WHERE RDB$PROCEDURE_NAME LIKE '".object."%'".
                \"ORDER BY RDB$PROCEDURE_NAME "
    return s:DB_FIREBIRD_execSql(query)
endfunction

function! s:DB_FIREBIRD_getListView(view_prefix)
    let owner   = s:DB_getObjectOwner(a:view_prefix)
    let object  = s:DB_getObjectName(a:view_prefix)
    let query = "SELECT DISTINCT RDB$VIEW_NAME ".
                \" FROM RDB$VIEW_RELATIONS ".
                \"WHERE RDB$VIEW_NAME LIKE '".object."%'".
                \"ORDER BY RDB$VIEW_NAME "
    return s:DB_FIREBIRD_execSql(query)
endfunction 

function! s:DB_FIREBIRD_getListColumn(table_name) "{{{
    let owner      = s:DB_getObjectOwner(a:table_name)
    let table_name = s:DB_getObjectName(a:table_name)
    let query = ''.
                \ "SELECT f.rdb$field_name ".
                \ "  FROM rdb$relation_fields f ".
                \ "  JOIN rdb$relations r ".
                \ "    ON f.rdb$relation_name = r.rdb$relation_name ".
                \ "   AND r.rdb$view_blr IS NULL ".
                \ "   AND ( ".
                \ "           r.rdb$system_flag IS NULL ".
                \ "        OR r.rdb$system_flag   = 0 ".
                \ "       ) ".
                \ " WHERE f.rdb$relation_name = '".table_name."' ".
                \ " ORDER BY f.rdb$field_position "
    let result = s:DB_FIREBIRD_execSql( query )
    return s:DB_FIREBIRD_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_FIREBIRD_stripHeaderFooter(result) "{{{
    " RDB$RELATION_NAME
    " RDB$FIELD_NAME
    " ===============================================================================
    " ==============================
    " =================================================
    " COUNTRY
    " COUNTRY
    "
    " COUNTRY
    " CURRENCY
    "
    " Strip off column headers ending with a newline
    let stripped = substitute( a:result, '\_.*=\s*'."[\<C-J>]", '', '' )
    " Strip off trailing spaces
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*\(\n\)', '\1\2', '' )
    return stripped
endfunction "}}}

function! s:DB_FIREBIRD_getDictionaryTable() "{{{
    let result = s:DB_FIREBIRD_getListTable('')
    return s:DB_FIREBIRD_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_FIREBIRD_getDictionaryProcedure() "{{{
    let result = s:DB_FIREBIRD_getListProcedure('')
    return s:DB_FIREBIRD_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_FIREBIRD_getDictionaryView() "{{{
    let result = s:DB_FIREBIRD_getListView('')
    return s:DB_FIREBIRD_stripHeaderFooter(result)
endfunction "}}}
"}}}
" DBI (Perl) exec {{{
function! s:DB_DBI_Autoload()
    if !exists("g:loaded_dbext_dbi") 
        if has('perl')
            " Load the perl based module (if not already)
            call dbext_dbi#DBI_load_perl_subs()

            if !exists("g:loaded_dbext_dbi") 
                call s:DB_warningMsg( 
                            \ 'dbext:The DBI interface could not be loaded, ensure autoload/dbext_dbi.vim exists'
                            \ )
            endif
        else
            return -1
        endif
    endif

    if g:loaded_dbext_dbi == -1
        " Plugin detected bad conditions
        let msg = 'dbext:The DBI interface could not be loaded'
        if exists('g:loaded_dbext_dbi_msg') 
            let msg = msg . ':' . g:loaded_dbext_dbi_msg
        endif
        call s:DB_warningMsg( msg )
        return -1 
    endif

    if !exists("g:dbext_dbi_loaded_perl_subs") 
        " Load the perl based module (if not already)
        call dbext_dbi#DBI_load_perl_subs()
    endif

    " if exists('g:loaded_dbext_dbi_msg') 
    "     call s:DB_warningMsg( 
    "                 \ 'dbext:The DBI interface could not be loaded:'.
    "                 \ g:loaded_dbext_dbi_msg
    "                 \ )
    "     return -1
    " endif

    if !exists("g:dbext_dbi_loaded_perl_subs") 
        let msg = 'dbext:The DBI interface could not be loaded'
        if exists('g:loaded_dbext_dbi_msg') 
            let msg = msg . ':'. g:loaded_dbext_dbi_msg
        endif

        call s:DB_warningMsg( msg )
        return -1
    endif

    return 0
endfunction

function! s:DB_DBI_execSql(str)

    let result = ""
    let read_file_cmd    = s:DB_get('DBI_read_file_cmd') 
    let split_on_pattern = s:DB_get('DBI_split_on_pattern') 
    let cmd_terminator   = s:DB_get('DBI_cmd_terminator')

    let str = a:str

    " First iterate through the SQL looking for a read_file_cmd.
    " If found, check if the following text specifies a filename.
    " If so, replace the read_file_cmd and filename with the
    " contents of the file.  
    " Continue on looking for additional read_file_cmd statements.
    if read_file_cmd != ""
        let index = 0
        " Find the string index position of the first match
        let index = match( str, escape(read_file_cmd, '\\/.*$^~[]') )
        while index > -1
            " Check to see if the current line is a comment, if so ignore
            " the line and continue checking
            " Regex:
            "     ".*\n"          - Grab all characters up to the most current
            "                       newline
            "     \s*             - Ignore whitespace after the newline
            "     \zs             - Start the match
            "     \(              - Group next non-whitepsace
            "         \S\+.\{-}   - Any non-white characters (minimal)
            "     \)\?            - This group is optional
            "     \%              - Up to the exact match of the read_file_cmd
            "     (index+2)       - Not exactly sure why +2 is necessary
            "     c               - Match up to the read_file_cmd
            "     \ze             - End the match
            "     .*              - Ignore all trailing characters
            let line_starting_chars = matchstr("\n".str, ".*\n".'\s*\zs\(\S\+.\{-}\)\?\%'.(index+2).'c\ze.*')
            " Compare this against the comment characters based on the 
            " current filetype
            " The line_starting_chars are the first non-white space on the
            " line, so compare this against the start of the match ^
            if line_starting_chars =~ '^\('.s:DB_getCommentChars().'\)'
                let index = index + len(read_file_cmd)
            else
                " Use the isfname option to lookup what might be a filename
                let filename = matchstr(str, '\f\+', index + len(read_file_cmd) )
                " Check if the filename is readable
                if filereadable(filename)
                    let sqlf = readfile(filename)
                    " Determine length of replacement string
                    let sub_len = len(read_file_cmd)+len(filename)
                    " Check if the read command is terminated
                    if match(str, '\%'.(sub_len+1).'c'.cmd_terminator, index) > 0
                        let sub_len = sub_len + len(cmd_terminator)
                    endif
                    " Use substitue to replace the read_file_cmd and the filename
                    " with the contents of the file
                    let str  = substitute(
                                \ str,
                                \ '\%'.(index+1).'c.\{'.(sub_len).'}',
                                \ join(sqlf, "\n"),
                                \ ''
                                \ )
                    " Do not advance the index since we just replaced the
                    " read statement with new SQL which must also be checked.
                    let index = index
                else
                    " Since the filename was unreadable, skip the read_file_cmd
                    " but not the filename since we don't really know what it
                    " might be at this point.
                    let index = index + len(read_file_cmd)
                endif
            endif
            " Skip this match and move on to the next
            let index = match(str, escape(read_file_cmd, '\\/.*$^~[]'), index)
        endwhile
    endif

    " Check if there are any statements which must be separated into separate
    " individual statements.  In SQL Anywhere, ASE, SQL Server these can be
    " statements separated by a "go" command.  If an error is encountered
    " while processing one of these split statements, processing is stopped
    " and the error is displayed to the user.
    if split_on_pattern == ""
        return s:DB_DBI_execStr(str)
    else
        let statements = split("\n".str, split_on_pattern)

        if !empty(statements)
            let idx     = 0
            let results = []
            for sql in statements
                if sql !~ '^[ \t\n]*$'
                    " Strip leading and trailing newlines
                    let sql =  substitute(sql, '^\n*\(.\{-}\)\n*$', '\1', 'g')
                    let result = s:DB_DBI_execStr(sql)
                    let results = add( results, result )
                    if result == -1
                        " Do not break, and continue executing.
                        " break
                        " If there was an error, stop and report it.
                        return -1
                    endif
                endif
            endfor
            return join( results, "\n" )
        endif
    endif
    return result
endfunction

function! s:DB_DBI_execStr(str)
    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    " Since the string will be enclosed in single quotes, we must first
    " espace any single quotes in the SQL
    " let sql = substitute(a:str, "'", "\\'", 'g')
    " exec "perl db_query('".a:str."')"
    let g:dbext_dbi_sql = a:str
    perl db_query()
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI", g:dbext_dbi_sql, g:dbext_dbi_msg)
        return -1
    endif

    let result = g:dbext_dbi_result
    call s:DB_runCmd("perl DBI", a:str, result)

    return result
endfunction

function! s:DB_DBI_describeTable(table_name)
    let owner      = s:DB_getObjectOwner(a:table_name)
    let table_name = s:DB_getObjectName(a:table_name)

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    let owner = (owner == ''?'undef':"'".owner."'")
    
    let cmd = "perl db_catalogue('COLUMN', ".owner.", '".table_name."', '%')"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI", cmd, g:dbext_dbi_msg)
        return -1
    endif

    let result = g:dbext_dbi_result
    call s:DB_runCmd("perl DBI", cmd, result)

    return result
endfunction

function! s:DB_DBI_describeProcedure(procedure_name)
    let owner   = s:DB_getObjectOwner(a:procedure_name)
    let object  = s:DB_getObjectName(a:procedure_name)

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    " Get the name of the driver we are using
    let driver       = s:DB_get('driver')

    " Since the string will be enclosed in single quotes, we must first
    " espace any single quotes in the SQL
    let g:dbext_dbi_sql = s:DB_get("DBI_desc_proc_".driver)

    if g:dbext_dbi_sql == ""
        call s:DB_warningMsg(
                    \ 'dbext:Please define "g:dbext_default_DBI_desc_proc_'.
                    \ driver.
                    \ '" with the SQL necessary to retrieve the correct information'.
                    \ ' from your database.  Please also send this SQL to the'.
                    \ ' author, David Fishburn for inclusion in a future version.'
                    \ )
        return -1
    endif

    " The owner name can be optionally followed by a "." due to the syntax of
    " some of the different databases (ASE and SQL Server)
    let g:dbext_dbi_sql = substitute(g:dbext_dbi_sql, 'dbext_replace_owner\.\?', owner, 'g')
    let g:dbext_dbi_sql = substitute(g:dbext_dbi_sql, 'dbext_replace_name', object, 'g')
    
    let cmd = "perl db_query()"
    exec cmd
    if g:dbext_dbi_result == -1
        call s:DB_runCmd("perl DBI", g:dbext_dbi_sql, g:dbext_dbi_msg)
        return -1
    endif

    let result = g:dbext_dbi_result
    call s:DB_runCmd("perl DBI", g:dbext_dbi_sql, result)

    return result
    " call s:DB_warningMsg( 'dbext:The DBI interface does not support procedure metadata' )
    " return ""
endfunction

function! s:DB_DBI_stripHeaderFooter(result)
    " Strip off column headers ending with a newline
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-J>]", '', '' )
    " Strip off query statistics
    let stripped = substitute( stripped, '(\d\+ rows\_.*', '', '' )
    " Strip off trailing spaces
    " let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*\(\n\)', '\1\2', '' )
    return stripped
endfunction

function! s:DB_DBI_getListColumn(table_name)
    let owner      = s:DB_getObjectOwner(a:table_name)
    let table_name = s:DB_getObjectName(a:table_name)

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    let owner = (owner == ''?'undef':"'".owner."'")

    let cmd = "perl db_catalogue('COLUMN', ".owner.", '".table_name."', '%')"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI", cmd, g:dbext_dbi_msg)
        return -1
    endif

    perl db_results_variable()

    let col_names  = matchstr(g:dbext_dbi_result,'DBI:.\{-}\zsTABLE_CAT.\{-}\ze\n')
    let col_values = matchstr(g:dbext_dbi_result,'\n-[ -]*\zs\n.*')
    " Strip off query statistics
    let col_values = substitute( col_values, '(\d\+ rows\_.*', '', '' )
    let pos_column = match(col_names, 'COLUMN_NAME')
    let pos_type   = match(col_names, 'DATA_TYPE')

    if col_names == ""
        call s:DB_warningMsg('DBI: No column info returned')
        return ""
    endif

    if pos_column !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find column name position')
        return ""
    endif

    if pos_type !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find data type position')
        return ""
    endif

    " For each row returned
    " Strip off the unneeded values (pos_column - 1)
    " Gather just the values we want (pos_type - pos_column)
    " Ignore the remainder of the line
    let col_regex  = '\n.\{'.(pos_column-1).'}.\(.\{'.(pos_type-pos_column).'}\).\{-}\ze\n'
    
    " Join them together with a newline separator
    let col_list = substitute(col_values, col_regex, '\1\n', 'g')

    return col_list
endfunction 

function! s:DB_DBI_getListTable(table_prefix)
    let owner      = s:DB_getObjectOwner(a:table_prefix)
    let table_name = s:DB_getObjectName(a:table_prefix)

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    " If empty, use undef, if not, place single quotes around it and add a %
    let owner      = (owner == ''?'undef':"'".owner."%'")
    let table_name = (table_name == ''?'undef':"'".table_name."%'")
    let driver     = s:DB_get('driver')
    let table_type = s:DB_getDefault('DBI_table_type_'.driver)
    if table_type == ""
        let table_type = s:DB_getDefault('DBI_table_type')
    endif
    let table_type = "'".table_type."'"

    let cmd = "perl db_catalogue('TABLE', ".table_type.", ".owner.", ".table_name.")"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI", cmd, g:dbext_dbi_msg)
        return -1
    endif

    let result = g:dbext_dbi_result
    call s:DB_runCmd("perl DBI", cmd, result)

    return result
endfunction

function! s:DB_DBI_getListProcedure(proc_prefix)
    let owner   = s:DB_getObjectOwner(a:proc_prefix)
    let object  = s:DB_getObjectName(a:proc_prefix)

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    " Get the name of the driver we are using
    let driver       = s:DB_get('driver')

    " Since the string will be enclosed in single quotes, we must first
    " espace any single quotes in the SQL
    let g:dbext_dbi_sql = s:DB_get("DBI_list_proc_".driver)

    if g:dbext_dbi_sql == ""
        call s:DB_warningMsg(
                    \ 'dbext:Please define "g:dbext_default_DBI_list_proc_'.
                    \ driver.
                    \ '" with the SQL necessary to retrieve the correct information'.
                    \ ' from your database.  Please also send this SQL to the'.
                    \ ' author, David Fishburn for inclusion in a future version.'
                    \ )
        return -1
    endif

    let g:dbext_dbi_sql = substitute(g:dbext_dbi_sql, 'dbext_replace_owner', owner, 'g')
    let g:dbext_dbi_sql = substitute(g:dbext_dbi_sql, 'dbext_replace_name', object, 'g')
    
    let cmd = "perl db_query()"
    exec cmd
    if g:dbext_dbi_result == -1
        call s:DB_runCmd("perl DBI", g:dbext_dbi_sql, g:dbext_dbi_msg)
        return -1
    endif

    let result = g:dbext_dbi_result
    call s:DB_runCmd("perl DBI", cmd, result)

    return result
endfunction

function! s:DB_DBI_getListView(view_prefix)
    let owner      = s:DB_getObjectOwner(a:view_prefix)
    let view_name  = s:DB_getObjectName(a:view_prefix)

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    " If empty, use undef, if not, place single quotes around it and add a %
    let owner     = (owner == ''?'undef':"'".owner."%'")
    let view_name = (view_name == ''?'undef':"'".view_name."%'")
    let view_type = "'".s:DB_getDefault('DBI_view_type')."'"

    let cmd = "perl db_catalogue('VIEW', ".view_type.", ".owner.", ".view_name.")"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI", cmd, g:dbext_dbi_msg)
        return -1
    endif

    let result = g:dbext_dbi_result
    call s:DB_runCmd("perl DBI", cmd, result)

    return result
endfunction 
function! s:DB_DBI_getDictionaryTable() "{{{

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    let driver     = s:DB_get('driver')
    let table_type = s:DB_getDefault('DBI_table_type_'.driver)
    if table_type == ""
        let table_type = s:DB_getDefault('DBI_table_type')
    endif
    let table_type = "'".table_type."'"

    let cmd = "perl db_catalogue('TABLE', ".table_type.", undef, undef)"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI", cmd, g:dbext_dbi_msg)
        return -1
    endif

    let cmd = "perl db_results_variable()"
    exec cmd
    if g:dbext_dbi_result == -1
        call s:DB_runCmd("perl DBI", cmd, g:dbext_dbi_msg)
        return -1
    endif

    let col_names  = matchstr(g:dbext_dbi_result,'DBI:.\{-}\zsTABLE_CAT.\{-}\ze\n')
    let col_values = matchstr(g:dbext_dbi_result,'\n-[ -]*\zs\n.*')
    " Strip off query statistics
    let col_values = substitute( col_values, '(\d\+ rows\_.*', '', '' )
    let pos_owner  = match(col_names, 'TABLE_SCHEM')
    let pos_table  = match(col_names, 'TABLE_NAME')
    let pos_type   = match(col_names, 'TABLE_TYPE')

    if col_names == ""
        call s:DB_warningMsg('DBI: No column info returned')
        return ""
    endif

    if pos_owner !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find owner name position')
        return ""
    endif

    if pos_table !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find table name position')
        return ""
    endif

    if pos_type !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find table type position')
        return ""
    endif

    let col_regex  = '\n'

    let has_owner  = 1
    let table_owner = matchstr(col_values, '\n.\{'.(pos_owner).'}\zs.\{'.(pos_table-pos_owner).'}')
    if table_owner =~ '^\s' || table_owner =~ '^NULL.*' 
        let has_owner = 0
        let col_regex .= '.\{'.(pos_table).'}'
    else
        " Grab the owner/creator name
        let col_regex .= '.\{'.(pos_owner-1).'}.\(.\{'.(pos_table-pos_owner).'}\)'
    endif

    let replace = '\1\n'
    if has_owner == 1
        if s:DB_get('dict_show_owner') == 1
            let replace = '\1.\2\n'
        else
            let replace = '\2\n'
        endif
    endif

    " For each row returned
    " Strip off the unneeded values (pos_table - 1)
    " Gather just the values we want (pos_type - pos_table)
    " Ignore the remainder of the line
    let col_regex .= '\(.\{'.(pos_type-pos_table).'}\).\{-}\ze\n'
    
    " Join them together with a newline separator
    let obj_list = substitute(col_values, col_regex, replace, 'g')
    " If an owner exists, there will be spaces between the 
    " name and the ., remove these spaces.
    if has_owner == 1 &&  s:DB_get('dict_show_owner') == 1
        let obj_list = substitute(obj_list, '\s\+\.', '.', 'g')
    endif

    return obj_list
endfunction "}}}
function! s:DB_DBI_getDictionaryProcedure() "{{{
    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    " Get the name of the driver we are using
    let driver       = s:DB_get('driver')

    " Since the string will be enclosed in single quotes, we must first
    " espace any single quotes in the SQL
    let g:dbext_dbi_sql = s:DB_get("DBI_dict_proc_".driver)

    if g:dbext_dbi_sql == ""
        call s:DB_warningMsg(
                    \ 'dbext:Please define "g:dbext_default_DBI_dict_proc_'.
                    \ driver.
                    \ '" with the SQL necessary to retrieve the correct information'.
                    \ ' from your database.  Please also send this SQL to the'.
                    \ ' author, David Fishburn for inclusion in a future version.'
                    \ )
        return -1
    endif
    
    let cmd = "perl db_query()"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_warningMsg(g:dbext_dbi_msg."\nSQL:".g:dbext_dbi_sql)
        return -1
    endif

    " Populate the results variable
    perl db_results_variable()

    let result = g:dbext_dbi_result
    let result = s:DB_DBI_stripHeaderFooter(result)

    return result
endfunction "}}}
function! s:DB_DBI_getDictionaryView() "{{{

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    let driver    = s:DB_get('driver')
    let view_type = s:DB_getDefault('DBI_view_type_'.driver)
    if view_type == ""
        let view_type = s:DB_getDefault('DBI_view_type')
    endif
    let view_type = "'".view_type."'"

    let cmd = "perl db_catalogue('VIEW', ".view_type.", '%', '%')"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI", cmd, g:dbext_dbi_msg)
        return -1
    endif

    " Populate the results variable
    perl db_results_variable()

    let col_names  = matchstr(g:dbext_dbi_result,'DBI:.\{-}\zsTABLE_CAT.\{-}\ze\n')
    let col_values = matchstr(g:dbext_dbi_result,'\n-[ -]*\zs\n.*')
    " Strip off query statistics
    let col_values = substitute( col_values, '(\d\+ rows\_.*', '', '' )
    let pos_owner  = match(col_names, 'TABLE_SCHEM')
    let pos_table  = match(col_names, 'TABLE_NAME')
    let pos_type   = match(col_names, 'TABLE_TYPE')

    if col_names == ""
        call s:DB_warningMsg('DBI: No column info returned')
        return ""
    endif

    if pos_owner !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find owner name position')
        return ""
    endif

    if pos_table !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find table name position')
        return ""
    endif

    if pos_type !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find table type position')
        return ""
    endif

    let col_regex  = '\n'

    let has_owner  = 1
    let table_owner = matchstr(col_values, '\n.\{'.(pos_owner).'}\zs.\{'.(pos_table-pos_owner).'}')
    if table_owner =~ '^\s' || table_owner =~ '^NULL.*' 
        let has_owner = 0
        let col_regex .= '.\{'.(pos_table).'}'
    else
        " Grab the owner/creator name
        let col_regex .= '.\{'.(pos_owner-1).'}.\(.\{'.(pos_table-pos_owner).'}\)'
    endif

    let replace = '\1\n'
    if has_owner == 1
        if s:DB_get('dict_show_owner') == 1
            let replace = '\1.\2\n'
        else
            let replace = '\2\n'
        endif
    endif

    " For each row returned
    " Strip off the unneeded values (pos_table - 1)
    " Gather just the values we want (pos_type - pos_table)
    " Ignore the remainder of the line
    let col_regex .= '\(.\{'.(pos_type-pos_table).'}\).\{-}\ze\n'
    
    " Join them together with a newline separator
    let obj_list = substitute(col_values, col_regex, replace, 'g')
    " If an owner exists, there will be spaces between the 
    " name and the ., remove these spaces.
    if has_owner == 1 &&  s:DB_get('dict_show_owner') == 1
        let obj_list = substitute(obj_list, '\s\+\.', '.', 'g')
    endif

    return obj_list
endfunction "}}}
function! s:DB_DBI_setOption(option_name, value) "{{{
    let option_name = a:option_name

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    let cmd = "perl db_set_connection_option('".option_name."', '".a:value."')"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI", cmd, g:dbext_dbi_msg)
        return -1
    endif

    return 0
endfunction "}}}
"}}}
" ODBC exec {{{
function! s:DB_ODBC_execSql(str)
    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    " Since the string will be enclosed in single quotes, we must first
    " espace any single quotes in the SQL
    " let sql = substitute(a:str, "'", "\\'", 'g')
    " exec "perl db_query('".a:str."')"
    let g:dbext_dbi_sql = a:str
    perl db_query()
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI::ODBC", g:dbext_dbi_sql, g:dbext_dbi_msg)
        return -1
    endif

    let result = g:dbext_dbi_result
    call s:DB_runCmd("perl DBI::ODBC", a:str, result)

    return result
endfunction

function! s:DB_ODBC_describeTable(table_name)
    let owner      = s:DB_getObjectOwner(a:table_name)
    let table_name = s:DB_getObjectName(a:table_name)

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    let owner = (owner == ''?'undef':"'".owner."'")
    
    let cmd = "perl db_odbc_catalogue('COLUMN', ".owner.", '".table_name."', undef)"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI::ODBC", cmd, g:dbext_dbi_msg)
        return -1
    endif

    let result = g:dbext_dbi_result
    call s:DB_runCmd("perl DBI::ODBC", cmd, result)

    return result
endfunction

function! s:DB_ODBC_describeProcedure(procedure_name)
    let owner   = s:DB_getObjectOwner(a:procedure_name)
    let object  = s:DB_getObjectName(a:procedure_name)

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    " Ask the driver for the name of the RDBMS we are connected to
    perl db_get_info(17)

    let rdbms = g:dbext_dbi_result

    let driver = ''
    if rdbms =~? 'Anywhere'
        let driver = 'SQLAnywhere'
    elseif rdbms =~? 'SQL\s*Server'
        let driver = 'SQLSRV'
    elseif rdbms =~? 'mysql'
        let driver = 'mysql'
    elseif rdbms =~? 'oracle'
        let driver = 'Oracle'
    elseif rdbms =~? 'db2'
        let driver = 'DB2'
    elseif rdbms =~? 'postgres'
        let driver = 'PGSQL'
    else
        call s:DB_warningMsg(
                    \ 'dbext:Please report this ODBC driver ['.
                    \ rdbms.
                    \ '] to the author, '.
                    \ ' David Fishburn for inclusion in a future version.'
                    \ )
        return -1
    endif

    " Since the string will be enclosed in single quotes, we must first
    " espace any single quotes in the SQL
    let g:dbext_dbi_sql = s:DB_get("DBI_desc_proc_".driver)

    if g:dbext_dbi_sql == ""
        call s:DB_warningMsg(
                    \ 'dbext:Please define "g:dbext_default_DBI_desc_proc_'.
                    \ driver.
                    \ '" with the SQL necessary to retrieve the correct information'.
                    \ ' from your database.  Please also send this SQL to the'.
                    \ ' author, David Fishburn for inclusion in a future version.'
                    \ )
        return -1
    endif

    " The owner name can be optionally followed by a "." due to the syntax of
    " some of the different databases (ASE and SQL Server)
    let g:dbext_dbi_sql = substitute(g:dbext_dbi_sql, 'dbext_replace_owner\.\?', owner, 'g')
    let g:dbext_dbi_sql = substitute(g:dbext_dbi_sql, 'dbext_replace_name', object, 'g')
    
    let cmd = "perl db_query()"
    exec cmd
    if g:dbext_dbi_result == -1
        call s:DB_runCmd("perl DBI", g:dbext_dbi_sql, g:dbext_dbi_msg)
        return -1
    endif

    let result = g:dbext_dbi_result
    call s:DB_runCmd("perl DBI", g:dbext_dbi_sql, result)

    return result
    call s:DB_warningMsg( 'dbext:The DBI::ODBC interface does not support procedure metadata' )
    return ""
endfunction

function! s:DB_ODBC_stripHeaderFooter(result)
    " Strip off column headers ending with a newline
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-J>]", '', '' )
    " Strip off query statistics
    let stripped = substitute( stripped, '(\d\+ rows\_.*', '', '' )
    " Strip off trailing spaces
    " let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*\(\n\)', '\1\2', '' )
    return stripped
endfunction

function! s:DB_ODBC_getListColumn(table_name)
    let owner      = s:DB_getObjectOwner(a:table_name)
    let table_name = s:DB_getObjectName(a:table_name)

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    let owner = (owner == ''?'undef':"'".owner."'")

    let cmd = "perl db_odbc_catalogue('COLUMN', ".owner.", '".table_name."', undef)"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI::ODBC", cmd, g:dbext_dbi_msg)
        return -1
    endif

    perl db_results_variable()

    let col_names  = matchstr(g:dbext_dbi_result,'DBI:.\{-}\zsTABLE_CAT.\{-}\ze\n')
    let col_values = matchstr(g:dbext_dbi_result,'\n-[ -]*\zs\n.*')
    " Strip off query statistics
    let col_values = substitute( col_values, '(\d\+ rows\_.*', '', '' )
    let pos_column = match(col_names, 'COLUMN_NAME')
    let pos_type   = match(col_names, 'DATA_TYPE')

    if col_names == ""
        call s:DB_warningMsg('DBI: No column info returned')
        return ""
    endif

    if pos_column !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find column name position')
        return ""
    endif

    if pos_type !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find data type position')
        return ""
    endif

    " For each row returned
    " Strip off the unneeded values (pos_column - 1)
    " Gather just the values we want (pos_type - pos_column)
    " Ignore the remainder of the line
    let col_regex  = '\n.\{'.(pos_column-1).'}.\(.\{'.(pos_type-pos_column).'}\).\{-}\ze\n'
    
    " Join them together with a newline separator
    let col_list = substitute(col_values, col_regex, '\1\n', 'g')

    return col_list
endfunction 

function! s:DB_ODBC_getListTable(table_prefix)
    let owner      = s:DB_getObjectOwner(a:table_prefix)
    let table_name = s:DB_getObjectName(a:table_prefix)

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    " If empty, use undef, if not, place single quotes around it and add a %
    let owner      = (owner == ''?'undef':"'".owner."%'")
    let table_name = (table_name == ''?'undef':"'".table_name."%'")

    let cmd = "perl db_odbc_catalogue('TABLE', 'TABLE', ".owner.", ".table_name.")"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI::ODBC", cmd, g:dbext_dbi_msg)
        return -1
    endif

    let result = g:dbext_dbi_result
    call s:DB_runCmd("perl DBI::ODBC", cmd, result)

    return result
endfunction

function! s:DB_ODBC_getListProcedure(proc_prefix)
    let owner   = s:DB_getObjectOwner(a:proc_prefix)
    let object  = s:DB_getObjectName(a:proc_prefix)

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    " Ask the driver for the name of the RDBMS we are connected to
    perl db_get_info(17)

    let rdbms = g:dbext_dbi_result

    let driver = ''
    if rdbms =~? 'Anywhere'
        let driver = 'SQLAnywhere'
    elseif rdbms =~? 'SQL\s*Server'
        let driver = 'SQLSRV'
    elseif rdbms =~? 'mysql'
        let driver = 'mysql'
    elseif rdbms =~? 'oracle'
        let driver = 'Oracle'
    elseif rdbms =~? 'db2'
        let driver = 'DB2'
    elseif rdbms =~? 'postgres'
        let driver = 'PGSQL'
    else
        call s:DB_warningMsg(
                    \ 'dbext:Please report this ODBC driver ['.
                    \ rdbms.
                    \ '] to the author, '.
                    \ ' David Fishburn for inclusion in a future version.'
                    \ )
        return -1
    endif

    " Since the string will be enclosed in single quotes, we must first
    " espace any single quotes in the SQL
    let g:dbext_dbi_sql = s:DB_get("DBI_list_proc_".driver)

    if g:dbext_dbi_sql == ""
        call s:DB_warningMsg(
                    \ 'dbext:Please define "g:dbext_default_DBI_list_proc_'.
                    \ driver.
                    \ '" with the SQL necessary to retrieve the correct information'.
                    \ ' from your database.  Please also send this SQL to the'.
                    \ ' author, David Fishburn for inclusion in a future version.'
                    \ )
        return -1
    endif

    let g:dbext_dbi_sql = substitute(g:dbext_dbi_sql, 'dbext_replace_owner', owner, 'g')
    let g:dbext_dbi_sql = substitute(g:dbext_dbi_sql, 'dbext_replace_name', object, 'g')
    
    let cmd = "perl db_query()"
    exec cmd
    if g:dbext_dbi_result == -1
        call s:DB_runCmd("perl DBI::ODBC", g:dbext_dbi_sql, g:dbext_dbi_msg)
        return -1
    endif

    let result = g:dbext_dbi_result
    call s:DB_runCmd("perl DBI::ODBC", cmd, result)

    return result
endfunction

function! s:DB_ODBC_getListView(view_prefix)
    let owner      = s:DB_getObjectOwner(a:view_prefix)
    let view_name  = s:DB_getObjectName(a:view_prefix)

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    " If empty, use undef, if not, place single quotes around it and add a %
    let owner     = (owner == ''?'undef':"'".owner."%'")
    let view_name = (view_name == ''?'undef':"'".view_name."%'")
    let view_type = "'".s:DB_getDefault('DBI_view_type')."'"

    let cmd = "perl db_odbc_catalogue('VIEW', ".view_type.", ".owner.", ".view_name.")"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI::ODBC", cmd, g:dbext_dbi_msg)
        return -1
    endif

    let result = g:dbext_dbi_result
    call s:DB_runCmd("perl DBI::ODBC", cmd, result)

    return result
endfunction 
function! s:DB_ODBC_getDictionaryTable() "{{{

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    let table_type = "'".s:DB_getDefault('DBI_table_type')."'"

    let cmd = "perl db_odbc_catalogue('TABLE', 'TABLE', undef, undef)"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI::ODBC", cmd, g:dbext_dbi_msg)
        return -1
    endif

    perl db_results_variable()

    let col_names  = matchstr(g:dbext_dbi_result,'DBI:.\{-}\zsTABLE_CAT.\{-}\ze\n')
    let col_values = matchstr(g:dbext_dbi_result,'\n-[ -]*\zs\n.*')
    " Strip off query statistics
    let col_values = substitute( col_values, '(\d\+ rows\_.*', '', '' )
    let pos_owner  = match(col_names, 'TABLE_SCHEM')
    let pos_table  = match(col_names, 'TABLE_NAME')
    let pos_type   = match(col_names, 'TABLE_TYPE')

    if col_names == ""
        call s:DB_warningMsg('DBI: No column info returned')
        return ""
    endif

    if pos_owner !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find owner name position')
        return ""
    endif

    if pos_table !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find table name position')
        return ""
    endif

    if pos_type !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find table type position')
        return ""
    endif

    let col_regex  = '\n'

    let has_owner  = 1
    let table_owner = matchstr(col_values, '\n.\{'.(pos_owner).'}\zs.\{'.(pos_table-pos_owner).'}')
    if table_owner =~ '^\s' || table_owner =~ '^NULL.*' 
        let has_owner = 0
        let col_regex .= '.\{'.(pos_table).'}'
    else
        " Grab the owner/creator name
        let col_regex .= '.\{'.(pos_owner-1).'}.\(.\{'.(pos_table-pos_owner).'}\)'
    endif

    let replace = '\1\n'
    if has_owner == 1
        if s:DB_get('dict_show_owner') == 1
            let replace = '\1.\2\n'
        else
            let replace = '\2\n'
        endif
    endif

    " For each row returned
    " Strip off the unneeded values (pos_table - 1)
    " Gather just the values we want (pos_type - pos_table)
    " Ignore the remainder of the line
    let col_regex .= '\(.\{'.(pos_type-pos_table).'}\).\{-}\ze\n'
    
    " Join them together with a newline separator
    let obj_list = substitute(col_values, col_regex, replace, 'g')
    " If an owner exists, there will be spaces between the 
    " name and the ., remove these spaces.
    if has_owner == 1 &&  s:DB_get('dict_show_owner') == 1
        let obj_list = substitute(obj_list, '\s\+\.', '.', 'g')
    endif

    return obj_list
endfunction "}}}
function! s:DB_ODBC_getDictionaryProcedure() "{{{
    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    " Ask the driver for the name of the RDBMS we are connected to
    perl db_get_info(17)

    let rdbms = g:dbext_dbi_result

    let driver = ''
    if rdbms =~? 'Anywhere'
        let driver = 'SQLAnywhere'
    elseif rdbms =~? 'SQL\s*Server'
        let driver = 'SQLSRV'
    elseif rdbms =~? 'mysql'
        let driver = 'mysql'
    elseif rdbms =~? 'oracle'
        let driver = 'Oracle'
    elseif rdbms =~? 'db2'
        let driver = 'DB2'
    elseif rdbms =~? 'postgres'
        let driver = 'PGSQL'
    else
        call s:DB_warningMsg(
                    \ 'dbext:Please report this ODBC driver ['.
                    \ rdbms.
                    \ '] to the author, '.
                    \ ' David Fishburn for inclusion in a future version.'
                    \ )
        return -1
    endif

    " Since the string will be enclosed in single quotes, we must first
    " espace any single quotes in the SQL
    let g:dbext_dbi_sql = s:DB_get("DBI_dict_proc_".driver)

    if g:dbext_dbi_sql == ""
        call s:DB_warningMsg(
                    \ 'dbext:Please define "g:dbext_default_DBI_dict_proc_'.
                    \ driver.
                    \ '" with the SQL necessary to retrieve the correct information'.
                    \ ' from your database.  Please also send this SQL to the'.
                    \ ' author, David Fishburn for inclusion in a future version.'
                    \ )
        return -1
    endif
    
    let cmd = "perl db_query()"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_warningMsg(g:dbext_dbi_msg."\nSQL:".g:dbext_dbi_sql)
        return -1
    endif

    " Populate the results variable
    perl db_results_variable()

    let result = g:dbext_dbi_result
    let result = s:DB_DBI_stripHeaderFooter(result)

    return result
endfunction "}}}
function! s:DB_ODBC_getDictionaryView() "{{{

    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if dbext#DB_connect() == -1
        return -1
    endif

    let cmd = "perl db_odbc_catalogue('TABLE', 'VIEW', undef, undef)"
    exec cmd
    if g:dbext_dbi_result == -1
        " call s:DB_errorMsg(g:dbext_dbi_msg)
        call s:DB_runCmd("perl DBI::ODBC", cmd, g:dbext_dbi_msg)
        return -1
    endif

    perl db_results_variable()

    let col_names  = matchstr(g:dbext_dbi_result,'DBI:.\{-}\zsTABLE_CAT.\{-}\ze\n')
    let col_values = matchstr(g:dbext_dbi_result,'\n-[ -]*\zs\n.*')
    " Strip off query statistics
    let col_values = substitute( col_values, '(\d\+ rows\_.*', '', '' )
    let pos_owner  = match(col_names, 'TABLE_SCHEM')
    let pos_table  = match(col_names, 'TABLE_NAME')
    let pos_type   = match(col_names, 'TABLE_TYPE')

    if col_names == ""
        call s:DB_warningMsg('DBI: No column info returned')
        return ""
    endif

    if pos_owner !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find owner name position')
        return ""
    endif

    if pos_table !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find table name position')
        return ""
    endif

    if pos_type !~ '\d\+'
        call s:DB_errorMsg('DBI: Cannot find table type position')
        return ""
    endif

    let col_regex  = '\n'

    let has_owner  = 1
    let table_owner = matchstr(col_values, '\n.\{'.(pos_owner).'}\zs.\{'.(pos_table-pos_owner).'}')
    if table_owner =~ '^\s' || table_owner =~ '^NULL.*' 
        let has_owner = 0
        let col_regex .= '.\{'.(pos_table).'}'
    else
        " Grab the owner/creator name
        let col_regex .= '.\{'.(pos_owner-1).'}.\(.\{'.(pos_table-pos_owner).'}\)'
    endif

    let replace = '\1\n'
    if has_owner == 1
        if s:DB_get('dict_show_owner') == 1
            let replace = '\1.\2\n'
        else
            let replace = '\2\n'
        endif
    endif

    " For each row returned
    " Strip off the unneeded values (pos_table - 1)
    " Gather just the values we want (pos_type - pos_table)
    " Ignore the remainder of the line
    let col_regex .= '\(.\{'.(pos_type-pos_table).'}\).\{-}\ze\n'
    
    " Join them together with a newline separator
    let obj_list = substitute(col_values, col_regex, replace, 'g')
    " If an owner exists, there will be spaces between the 
    " name and the ., remove these spaces.
    if has_owner == 1 &&  s:DB_get('dict_show_owner') == 1
        let obj_list = substitute(obj_list, '\s\+\.', '.', 'g')
    endif

    return obj_list
endfunction "}}}
"}}}
" Selector functions {{{
" -AvR {{{
"  FIXME: This is a hack.  A better way to go about it is to change
"  DB_execSqlWithDefault to make use of DB_getSqlWithDefault for its execution
"  string to eliminate redundancy. Copied straight from DB_execSqlWithDefault.
function! dbext#DB_getSqlWithDefault(...)
    if (a:0 > 0)
        let sql = a:1
    else
        call s:DB_warningMsg("dbext:No statement to execute!")
        return
    endif
    if(a:0 > 1)
        " This will be a table name, check if there are any spaces,
        " if so, add double quotes
        if a:2 !~ '["\[\]]' && a:2 =~ '\w\s\+\w'
            let sql = sql . '"' . a:2 . '"'
        else
            let sql = sql . a:2
        endif
    else
        let sql = sql . expand("<cword>")
    endif
    
    return sql
endfunction
" }}}

function! dbext#DB_execSql(query)
    let query = a:query

    if strlen(query) == 0
        call s:DB_warningMsg("dbext:No statement to execute!")
        return -1
    endif

    " Mark the current line to return to
    let curline     = line(".")
    let curcol      = virtcol(".")

   " Add query to internal history
    call s:DB_historyAdd(query)
    
    " We need some additional database type information to continue
    if s:DB_get("buffer_defaulted") != 1
        let use_defaults = 1
        let rc = s:DB_resetBufferParameters(use_defaults)
        if rc == -1
            call s:DB_warningMsg( 
                        \ "dbext:A valid database type must ".
                        \ "be chosen" 
                        \ )
            return rc
        endif
    endif

    if s:DB_get("prompt_for_parameters") == "1"
        let query = dbext#DB_parseQuery(query)
    endif
    
    if query != ""
        let rc = dbext#DB_execFuncTypeWCheck('execSql', query)

        " Return to previous location
        " Accounting for beginning of the line
        " silent! exe 'norm! '.curline."G\<bar>".(curcol-1).(((curcol-1)> 0)?'l':'')
        call cursor(curline, curcol)

        return rc
    else
       " If the query was cancelled, close the history 
       " window which was opened when we added the 
       " query above.
        call dbext#DB_windowClose(s:DB_resBufName())
    endif

    " Return to previous location
    " Accounting for beginning of the line
    " silent! exe 'norm! '.curline."G\<bar>".(curcol-1).(((curcol-1)> 0)?'l':'')
    call cursor(curline, curcol)

    return -1
endfunction

function! dbext#DB_execSqlWithDefault(...)
    if (a:0 > 0)
        let sql = a:1
    else
        call s:DB_warningMsg("dbext:No statement to execute!")
        return
    endif
    if(a:0 > 1)
        if a:2 !~ '["\[\]]' && a:2 =~ '\w\s\+\w'
            let sql = sql . '"' . a:2 . '"'
        else
            let sql = sql . a:2
        endif
    else
        let sql = sql . expand("<cword>")
    endif
    
    return dbext#DB_execSql(sql)
endfunction

function! dbext#DB_execSqlTopX(...)
    if (a:0 > 0)
        let sql = a:1
    else
        call s:DB_warningMsg("dbext:No statement to execute!")
        return ""
    endif
    
    " We need some additional database type information to continue
    if s:DB_get("buffer_defaulted") != 1
        let use_defaults = 1
        let rc = s:DB_resetBufferParameters(use_defaults)
        if rc == -1
            call s:DB_warningMsg( "dbext:A valid database type must be chosen" )
            return ""
        endif
    endif

    let max_rows = input("How many rows to return? ")
    if max_rows !~ '\d\+'
        call s:DB_warningMsg("dbext:You must provide a numeric value")
        return ""
    endif

    let cur_rows = 0
    if s:DB_get('type') =~ '\<DBI\>\|\<ODBC\>'
        let cur_rows = s:DB_get('DBI_max_rows')
        call s:DB_set('DBI_max_rows', max_rows)
    else
        let top_pat  = dbext#DB_getWType("SQL_Top_pat")
        let top_sub  = dbext#DB_getWType("SQL_Top_sub")

        if top_pat == ""
            let msg = "dbext:No SQL TOP pattern defined.  ".
                        \ "You must define a g:dbext_default_".
                        \ s:DB_get("type").
                        \ "_SQL_Top_pat and a g:dbext_default_".
                        \ s:DB_get("type").
                        \ "_SQL_Top_sub"
            call s:DB_warningMsg(msg)
            return
        endif

        let sql = 
                    \   substitute(
                    \       substitute( sql, top_pat, top_sub, "" )
                    \       ,"@dbext_topX"
                    \       , max_rows
                    \       , ""
                    \   )
    endif
    let result = dbext#DB_execSql(sql)

    if s:DB_get('type') =~ '\<DBI\>\|\<ODBC\>'
        call s:DB_set('DBI_max_rows', cur_rows)
    endif

    return result
endfunction

function! dbext#DB_execRangeSql() range
    " Mark the current line to return to
    let curline     = a:lastline
    let curcol      = 0

    if a:firstline != a:lastline
        let saveR = @"
        silent! exec a:firstline.','.a:lastline.'y'
        let query = @"
        let @" = saveR
    else
        let query = getline(a:firstline)
    endif

    let rc = dbext#DB_execSql(query)

    " Return to previous location
    " Accounting for beginning of the line
    call cursor(curline, curcol)

    return rc
endfunction

function! s:DB_getLoginScript(filename)
    let sql = ''
    if a:filename != ''
        let sqlf = []
        " Use the isfname option to lookup what might be a filename
        let filename = matchstr(a:filename, '\f\+')

        " Check if the user has overridden the location where the login 
        " scripts will be saved
        let custom_login_script_dir = expand(s:DB_get('login_script_dir'))

        if custom_login_script_dir != ''
            if isdirectory(custom_login_script_dir)
                let filename = custom_login_script_dir.'/'.filename
                " Check if the filename is readable
                if filereadable(filename)
                    let sqlf = readfile(filename)
                else
                    " Since the filename was unreadable, report it to the user
                    call s:DB_warningMsg( 'dbext:Could not find login_script ['.a:filename.
                                \ '] in ['.custom_login_script_dir.']'
                                \ )
                    return sql
                endif
            else
                " Since the directory was unreadable, report it to the user
                call s:DB_warningMsg( 'dbext:Custom login_script_dir ['.custom_login_script_dir.
                            \ '] could not be found'
                            \ )
                return sql
            endif
        endif

        if custom_login_script_dir == ''
            let filename = expand('$VIM').'/'.filename
            " Check if the filename is readable
            if filereadable(filename)
                let sqlf = readfile(filename)
            else
                let filename = expand('$HOME').'/'.filename
                if filereadable(filename)
                    let sqlf = readfile(filename)
                else
                    " Since the filename was unreadable, report it to the user
                    call s:DB_warningMsg( 'dbext:Could not find login_script ['.a:filename.
                                \ '] in ['.expand('$VIM').'] or ['.
                                \ expand('$HOME').']'
                                \ )
                    return sql
                endif
            endif
        endif

        if len(sqlf) > 0 
            let sql = join(sqlf, "\n")."\n"
        endif
    endif

    return sql
endfunction

function! dbext#DB_describeTable(...)
    if(a:0 > 0)
        let table_name = s:DB_getObjectAndQuote(a:1)
    else
        let table_name = expand("<cword>")
    endif
    if table_name == ""
        call s:DB_warningMsg( 'dbext:You must supply a table name' )
        return ""
    endif

    return dbext#DB_execFuncTypeWCheck('describeTable', table_name)
endfunction

function! dbext#DB_describeProcedure(...)
    if(a:0 > 0)
        let procedure_name = s:DB_getObjectAndQuote(a:1)
    else
        let procedure_name = expand("<cword>")
    endif
    if procedure_name == ""
        call s:DB_warningMsg( 'dbext:You must supply a procedure name' )
        return ""
    endif

    return dbext#DB_execFuncTypeWCheck('describeProcedure', procedure_name)
endfunction

function! dbext#DB_getListColumn(table_name, silent_mode, use_newline_sep ) 
    let table_name      = a:table_name
    let silent_mode     = a:silent_mode
    let use_newline_sep = a:use_newline_sep

    " Remove any newline characters (especially from Visual mode)
    let table_name = substitute( table_name, "[\<C-J>]*", '', 'g' )
    if table_name == ""
        call s:DB_warningMsg( 'dbext:You must supply a table name' )
        return
    endif

    " This will return the result instead of using the result buffer
    let l:prev_use_result_buffer = s:DB_get('use_result_buffer')
    call s:DB_set('use_result_buffer', 0)
    let col_list = dbext#DB_execFuncTypeWCheck('getListColumn', table_name)
    call s:DB_set('use_result_buffer', l:prev_use_result_buffer)

    if col_list == '-1'
        call s:DB_warningMsg( 'dbext:Failed to create column list for ' .
                    \ table_name )
        return ''
    endif

    let col_list = s:DB_stripLeadFollowSpaceLines(col_list)

    " Remove all blanks and carriage returns to check for an empty string
    if strlen(col_list) < 2
        if silent_mode == 0
            call s:DB_warningMsg( 'dbext:Table not found: ' . table_name )
        endif
        return ''
    endif

    " " \<C-J> = Enter
    " " Strip off all leading spaces and newlines
    " let col_list = substitute( col_list, '^[ '."\<C-J>".']*\ze\w', '', '' )
    " " Strip off all following spaces and newlines
    " let col_list = substitute( col_list, '\w\>\zs[ '."\<C-J>".']*$', '\1', '' )

    if s:DB_get("use_tbl_alias") != 'n'
        let tbl_alias = s:DB_getTblAlias( table_name )
        " Add table alias to each column
        " let col_list = substitute( col_list, '\<\w\+\>', tbl_alias.'&', 'g' )
        let col_list = substitute( col_list, '\<\w.\{-}\n', tbl_alias.'&', 'g' )
    endif
    
    if use_newline_sep == 0
        " Convert newlines into commas
        " let col_list = substitute( col_list, '\w\>\zs[ '."\<C-J>".']*\ze\w', '\1, ', 'g' )
        " let col_list = substitute( col_list, '\w\>\zs[^.].\{-}\ze\<\w', ', ', 'g' )
        let col_list = substitute( col_list, '\s*\n', ', ', 'g' )
        " Make sure the column list does not end in a newline, makes
        " pasting into a buffer more difficult since  you cannot 
        " insert it between words
        " let col_list = substitute( col_list, ",\\?\\s*\\n$", '', '' )
        let col_list = substitute( col_list, '[, \t\r\n]*$', '', '' )
    else
        let col_list = substitute( col_list, ',\s*', "\n", 'g' )
    endif

    if &clipboard == 'unnamed'
        let @* = col_list 
    else
        let @@ = col_list 
    endif

    if silent_mode == 0
        echo 'Column list for ' . table_name . ' in paste register'
    endif

    return col_list
endfunction

function! dbext#DB_getListTable(...)
    if(a:0 > 0)
        " Strip any leading or trailing spaces
        let table_prefix = substitute(a:1,'\s*\(\w*\)\s*','\1','')
    else
        let table_prefix = s:DB_getInput( 
                    \ "Enter table prefix: ",
                    \ '',
                    \ "dbext_cancel"
                    \ )
        if table_prefix == "dbext_cancel" 
            return ""
        endif
    endif
    return dbext#DB_execFuncTypeWCheck('getListTable', table_prefix)
endfunction

function! dbext#DB_getListProcedure(...)
    if(a:0 > 0)
        " Strip any leading or trailing spaces
        let proc_prefix = substitute(a:1,'\s*\(\w*\)\s*','\1','')
    else
        let proc_prefix = s:DB_getInput( 
                    \ "Enter procedure prefix: ",
                    \ '',
                    \ "dbext_cancel"
                    \ )
        if proc_prefix == "dbext_cancel" 
            return ""
        endif
    endif
    return dbext#DB_execFuncTypeWCheck('getListProcedure', proc_prefix)
endfunction

function! dbext#DB_getListView(...)
    if(a:0 > 0)
        " Strip any leading or trailing spaces
        let view_prefix = substitute(a:1,'\s*\(\w*\)\s*','\1','')
    else
        let view_prefix = s:DB_getInput( 
                    \ "Enter view prefix: ",
                    \ '',
                    \ "dbext_cancel"
                    \ )
        if view_prefix == "dbext_cancel" 
            return ""
        endif
    endif
    return dbext#DB_execFuncTypeWCheck('getListView', view_prefix)
endfunction 

function! dbext#DB_getListConnections()
    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    " Record current buffer to return to the correct one
    let s:dbext_prev_winnr = winnr()
    let s:dbext_prev_bufnr = bufnr('%')

    " In order to parse a statement, we must know what database type
    " we are dealing with to choose the correct cmd_terminator
    if s:DB_get("buffer_defaulted") != 1
        let use_defaults = 1
        let rc = s:DB_resetBufferParameters(use_defaults)
        if rc == -1
            call s:DB_warningMsg( "dbext:A valid database type must be chosen" )
            return -1
        endif
    endif

    perl db_list_connections()
    if g:dbext_dbi_result == -1
        call s:DB_runCmd("perl DBI", "DBI connection list", g:dbext_dbi_msg)
        return -1
    endif

    let result = g:dbext_dbi_result
    call s:DB_runCmd("perl DBI", "DBI connection list", result)

    return result
endfunction

"}}}
" General {{{
function! s:DB_warningMsg(msg)
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction

function! s:DB_errorMsg(msg)
    echoerr a:msg
endfunction

function! dbext#DB_getQueryUnderCursor()
    let use_defaults = 1
    " In order to parse a statement, we must know what database type
    " we are dealing with to choose the correct cmd_terminator
    if s:DB_get("buffer_defaulted") != 1
        let rc = s:DB_resetBufferParameters(use_defaults)
        if rc == -1
            call s:DB_warningMsg( "dbext:A valid database type must be chosen" )
            return ""
        endif
    endif

    " Mi van olyankor, ha az idezojelben van pontosvesszo, vagy kulcsszo?
    " Van egy hiba gifem, majd meg kell nezni mi a rossz
    let old_sel = &sel
    let &sel = 'inclusive'
    let saveWrapScan=&wrapscan
    let saveSearch=@/
    let reg_z = @z
    let &wrapscan=0
    let @z = ''

    " If a command terminator has already been specified, use it
    " It is necessary to default it first, since this function
    " can be called before a buffer has setup which database it
    " will connect to.  The command terminator is different for
    " many databases.
    let dbext_cmd_terminator = dbext#DB_getWType('cmd_terminator')
    " If the cmd_terminator has any special characters, these must
    " be escaped before they can be used in a search string or
    " on the command line
    let dbext_cmd_terminator = s:DB_escapeStr(dbext_cmd_terminator)

    " Mark the current line to return to
    let curline     = line(".")
    let curcol      = virtcol(".")

    " Must default the statements to query
    let dbext_query_statements = s:DB_get("query_statements")
    " Verify the string is in the correct format
    " Strip off any trailing commas
    let dbext_query_statements =
                \ substitute(dbext_query_statements, ',$','','')
    " Convert commas to regex ors
    let dbext_query_statements =
                \ substitute(dbext_query_statements, '\s*,\s*', '\\|', 'g')

    " Make this a bit smarter, make sure there is whitespace from the 
    " beginning of the line here so that we do not pickup embedded
    " statements like:
    "      select 'insert into ...'
    "        from T1
    " This would have stopped at the INSERT word.  It is not perfect
    " but it is better with the check.
    let sql_commands = '\c^\s*\zs\<\('.dbext_query_statements.'\)\>'

    " Advance the cursor by 1 character incase the cursor is at the
    " beginning of one of the query statements
    if col('.') < (col('$')-1)
        exec 'normal! l'
    endif

    " Search backwards and do NOT wrap
    if search(sql_commands, 'bW' ) > 0
        " Note: escape the command terminator with \ in case the
        " string choosen is a special string.
        " I have tested this with the following terminators
        " ; ~ go
        " Note: I added the /e to the search string, since vim
        " was not picking up the command terminator as part of the
        " yank. This is generally not an issue since each of the
        " database exec sql routines add one, but if your
        " terminator is multiple characters (ie go - ASE and SQL Server)
        " then you get an invalid command since it was stripping
        " the "o" from "go"
        "
        " Make sure the cmd_terminator is the last item on the line,
        " in otherwords do not stop if the ; is part of a string:
        "    select 'insert into ...;'
        "      from T1
        " In the above case, we would stop even though the ; was
        " not the command terminator.

        " Start visual mode, find the terminator (should be at end of line)
        exe 'silent! norm! v/'.dbext_cmd_terminator."\\s*$/e\n".'"zy``'

        if line("'<") == line("'>") &&
                    \ col("'<") == col("'>")
            " No command terminator was found, so just use
            " the current lines content
            let @z = strpart(getline("'<"), (col("'<")-1))
        endif
    endif

    " Return to previous location
    " Accounting for beginning of the line
    " silent! exe 'norm! '.curline."G\<bar>".(curcol-1).(((curcol-1)> 0)?'l':'')
    call cursor(curline, curcol)

    noh
    let query = @z
    let @z = reg_z
    let @/=saveSearch
    let &wrapscan=saveWrapScan
    let &sel = old_sel

    return query
endfunction

function! dbext#DB_selectTablePrompt()
    return dbext#DB_execSql("select * from " .
                    \input("Please enter the name of the table to select from: "))
endfunction

function! dbext#DB_describeTablePrompt()
    return dbext#DB_describeTable(
                    \input("Please enter the name of the table to describe: "))
endfunction

function! dbext#DB_describeProcedurePrompt()
    return dbext#DB_describeProcedure(input("Please enter the name of the procedure to describe: "))
endfunction

function! s:DB_option(param, value, separator)
    if a:value == ""
        return ""
    else
        return a:param . a:value . a:separator
    endif
endfunction

function! s:DB_pad(side, length, value)
    let ret_val = a:value
    while strlen(ret_val) < a:length
        if a:side == "left"
            let ret_val = " " . ret_val
        else
            let ret_val = ret_val . " "
        endif
    endwhile
    return ret_val
endfunction

function! s:DB_getInput(prompt, default_value, cancel_value)
    if s:DB_get('inputdialog_cancel_support') == 1
        let val = inputdialog( a:prompt, a:default_value, a:cancel_value )
    else
        let val = inputdialog( a:prompt, a:default_value )
    endif

    if v:errmsg =~ '^E180' && s:DB_get('inputdialog_cancel_support') == 1
        " Workaround for the Vim7 bug in inputdialog
        let g:dbext_default_inputdialog_cancel_support = 0
        call s:DB_warningMsg("dbext:Vim7 bug found, setting g:dbext_default_inputdialog_cancel_support = 0")
        let val = inputdialog( a:prompt, a:default_value )
    endif

    return val
endfunction
function! s:DB_getObjectOwner(object) "{{{
    " The owner regex matches a word at the start of the string which is
    " followed by a dot, but doesn't include the dot in the result.
    " ^           - from beginning of line
    " \("\|\[\)\? - ignore any quotes
    " \zs         - start the match now
    " .\{-}       - get owner name
    " \ze         - end the match
    " \("\|\[\)\? - ignore any quotes
    " \.          - must by followed by a .
    " let owner = matchstr( a:object, '^\s*\zs.*\ze\.' )
    let owner = matchstr( a:object, '^\("\|\[\)\?\zs.\{-}\ze\("\|\]\)\?\.' )
    return owner
endfunction "}}}
function! s:DB_getObjectName(object) "{{{ 
    " The object regex matches a word at the start of the string, skipping over
    " any owner name if there is one.  Only the object name is returned.
    " ^               - from beginning of line
    " \(              - from beginning of line
    "     \("\|\[\)\? - ignore any quotes
    "     .\{-}       - get owner name
    "     \("\|\[\)\? - ignore any quotes
    "     \.          - must by followed by a .
    " \)\?            - All this is optional
    " \("\|\[\)\?     - ignore any quotes
    " \zs             - start the match now
    " .\{-}           - get owner name
    " \ze             - end the match
    " \("\|\[\)\?     - ignore any quotes
    " \s*$            - ignoring to the end of the line
    " let object  = matchstr( a:object, '^\(.*\.\)\?"\?\s*\zs.*' )
    let object  = matchstr( a:object, '^\(\("\|\[\)\?.\{-}\("\|\]\)\?\.\)\?\("\|\[\)\?\s*\zs.\{-}\ze\("\|\]\)\?\s*$' )
    return object
endfunction "}}}
function! s:DB_getObjectAndQuote(object) "{{{ 
    let owner = s:DB_getObjectOwner(a:object)
    let name  = s:DB_getObjectName(a:object)

    let object = ''

    if owner != ''
        let object = (owner =~ '\S\s\+\S'?'"'.owner.'"':owner).'.'
    endif
    if name != ''
        let object = object.(name =~ '\S\s\+\S'?'"'.name.'"':name)
    endif
    
    return object
endfunction "}}}
"}}}
" Dictionary (Completion) Functions {{{
function! s:DB_addBufDictList( buf_nbr ) "{{{
    if index(s:dbext_buffers_with_dict_files, a:buf_nbr) == -1
        call add(s:dbext_buffers_with_dict_files, a:buf_nbr)
    endif
    " if s:dbext_buffers_with_dict_files !~ '\<'.a:buf_nbr.','
    "     let s:dbext_buffers_with_dict_files = 
    "                 \ s:dbext_buffers_with_dict_files . a:buf_nbr . ','
    " endif
endfunction "}}}
function! s:DB_delBufDictList( buf_nbr ) "{{{
    " If the buffer has temporary files
    let idx = index(s:dbext_buffers_with_dict_files, a:buf_nbr) 
    if idx > -1
        " If all temporary files have been deleted
        if s:DB_get('dict_table_file') == '' && 
                    \ s:DB_get('dict_procedure_file') == '' && 
                    \ s:DB_get('dict_view_file') == ''
            " Remove the buffer number from the list
            call remove(s:dbext_buffers_with_dict_files, idx) 
        endif
    endif
    " if s:dbext_buffers_with_dict_files =~ '\<'.a:buf_nbr.','
    "     " If all temporary files have been deleted
    "     if s:DB_get('dict_table_file') == '' && 
    "                 \ s:DB_get('dict_procedure_file') == '' && 
    "                 \ s:DB_get('dict_view_file') == ''
    "         " Remove the buffer number from the list
    "         let s:dbext_buffers_with_dict_files = 
    "                     \ substitute( s:dbext_buffers_with_dict_files,
    "                     \ '\<' . a:buf_nbr . ',', 
    "                     \ '',
    "                     \ '' )
    "     endif
    " endif
endfunction "}}}
function! dbext#DB_DictionaryCreate( drop_dict, which ) "{{{
    " Store the lower case name, sometimes we use the 
    " a:which variable which has an Upper Case first letter,
    " but for variables names we use the lower case which_dict
    let which_dict = tolower(a:which)
    
    " First check if we are refreshing the table dictionary
    " If so, remove it 
    call s:DB_DictionaryDelete( which_dict )

    let temp_file = "-1"

    " Give the user the ability to remove a dictionary
    if a:drop_dict == 1
        return temp_file
    endif

    " In order to parse a statement, we must know what database type
    " we are dealing with to choose the correct cmd_terminator
    if s:DB_get("buffer_defaulted") != 1
        let use_defaults = 1
        let rc = s:DB_resetBufferParameters(use_defaults)
        if rc == -1
            return temp_file
        endif
    endif

    let max_rows = 0
    if s:DB_get('type') =~ '\<DBI\>\|\<ODBC\>'
        let max_rows = s:DB_get('DBI_max_rows')
        call s:DB_set('DBI_max_rows', 0)
    endif

    let l:prev_use_result_buffer = s:DB_get('use_result_buffer')
    call s:DB_set('use_result_buffer', 0)
    " let dict_list = s:DB_{b:dbext_type}_getDictionary{a:which}()
    let dict_list = dbext#DB_execFuncTypeWCheck('getDictionary'.a:which)
    call s:DB_set('use_result_buffer', l:prev_use_result_buffer)

    if dict_list != '-1'
        let dict_list = s:DB_stripLeadFollowSpaceLines(dict_list)

        " Create a new temporary file with the table names
        " let b:dbext_dict_{a:which}_file = tempname()
        let temp_file = tempname()
        call s:DB_set("dict_".which_dict."_file", temp_file )
        exe 'redir! > ' . temp_file
        silent echo dict_list."\n"
        redir END
        
        " Add the new temporary file to the dictionary setting for this buffer
        silent! exec 'setlocal dictionary+='.temp_file
        echo a:which . ' dictionary created'
        call s:DB_addBufDictList( bufnr("%") )
    else
        call s:DB_warningMsg( 'dbext:Failed to create ' . which_dict . ' dictionary' )
    endif

    if s:DB_get('type') =~ '\<DBI\>\|\<ODBC\>'
        call s:DB_set('DBI_max_rows', max_rows)
    endif

    return temp_file
endfunction "}}}
function! s:DB_DictionaryDelete( which ) "{{{
    let which_dict = tolower(a:which)
    let dict_file = s:DB_get("dict_".which_dict."_file")
    if strlen(dict_file) > 0
        " For this buffer, remove the file from the vim dictionary list
        silent! exec 'setlocal dictionary-='.dict_file

        " Now remove the temporary file
        let rc = delete(dict_file)
        if rc != 0
            call s:DB_warningMsg( 'dbext:Failed to delete ' . which_dict . ' dictionary: ' . 
                        \ dict_file .
                        \ '  rc: ' . rc )
        endif
        call s:DB_set("dict_".which_dict."_file", '')
        call s:DB_delBufDictList( bufnr("%") )
    endif
endfunction "}}}
function! dbext#DB_getDictionaryName( which ) "{{{
    " Provide the current temporary filename, this is used
    " by the Intellisense plugin
    let which_dict = tolower(a:which)
    let dict_file = s:DB_get("dict_".which_dict."_file")
    if strlen(dict_file) == 0
        if DB_DictionaryCreate( 0, a:which ) == -1
            return ""
        endif
    endif

    return s:DB_get("dict_".which_dict."_file")
endfunction "}}}
"}}}
" Autocommand Functions {{{
function! dbext#DB_auVimLeavePre() "{{{
    " Loop through all buffers
    " Disconnect if the buffer has a DBI or ODBC connection
    " Remove any dictionary files (if created)

    " Save the current buffer to switch back to
    let cur_buf = bufnr("%")

    for buf_nbr in s:dbext_buffers_with_dict_files
        " Switch to the buffer being deleted
        silent! exec buf_nbr.'buffer'

        call s:DB_DictionaryDelete( 'Table' )
        call s:DB_DictionaryDelete( 'Procedure' )
        call s:DB_DictionaryDelete( 'View' )
    endfor

    if exists('g:loaded_dbext_dbi')
        perl db_disconnect_all()
    endif

    if s:DB_get("delete_temp_file") == 1
        let rc = delete(s:dbext_tempfile)
    endif

    " Switch back to the current buffer
    silent! exec cur_buf.'buffer'
endfunction "}}}
function! dbext#DB_auVimLeavePreOld() "{{{
    " Loop through all buffers
    " Disconnect if the buffer has a DBI or ODBC connection
    " Remove any dictionary files (if created)

    redir => buffer_list
    silent! exec 'ls!'
    redir END

    " Convert the buffer list into a comma separated number list
    " :ls! returns a string like this
    "     1 %a   "dbext.vim"                    line 4144
    "     2  h   "dbext_dbi.vim"                line 144
    "     3u a-  "__Tag_List__"                 line 0
    "     4 #h   "\Vim\vimfiles\plugin\dbext.vim" line 366
    "     5u h-  "[Select Buf]"                 line 5
    "     6u a-  "windows.txt"                  line 943
    "     7u h-  "eval.txt"                     line 1789
    " This substitute command will create this list:
    "     1,2,3,4,5,6,7
    let buffer_list = substitute(buffer_list."\n", "\n".'\s\+\(\d\+\).\{-}\ze'."\n", '\1,', 'g')

    " Save the current buffer to switch back to
    let cur_buf = bufnr("%")

    " Find the first buffer number with temporary dictionary files created
    let buf_nbr = matchstr( buffer_list, '\d\+' )

    " For each buffer, cleanup the temporary dictionary files
    while strlen(buf_nbr) > 0
        " Switch to the buffer being deleted
        silent! exec buf_nbr.'buffer'

        " If the buffer connection parameters have not been 
        " defaulted, dbext has not been used.
        if s:DB_get("buffer_defaulted") != 1
            " Strip off the first buffer number from the list
            let buffer_list = substitute(buffer_list, '\d\+,', '', '')
            " Get the next buffer number
            let buf_nbr     = matchstr( buffer_list, '\d\+' )
            continue
        endif

        " If using the DBI layer, drop any connections which may be active
        if s:DB_get('type') =~ '\<DBI\>\|\<ODBC\>'
            call dbext#DB_disconnect()
        endif

        " If this buffer has dictionary files
        " if s:dbext_buffers_with_dict_files =~ ',\?'.buf_nbr.','
        if index(s:dbext_buffers_with_dict_files, a:buf_nbr) > -1
            " DB_DictionaryDelete will remove the buffer number from 
            " dbext_buffers_with_temp_files, so just match on the first #
            call s:DB_DictionaryDelete( 'Table' )
            call s:DB_DictionaryDelete( 'Procedure' )
            call s:DB_DictionaryDelete( 'View' )
        endif

        " Strip off the first buffer number from the list
        let buffer_list = substitute(buffer_list, '\d\+,', '', '')
        " Get the next buffer number
        let buf_nbr     = matchstr( buffer_list, '\d\+' )
    endwhile

    if s:DB_get("delete_temp_file") == 1
        let rc = delete(s:dbext_tempfile)
    endif

    " Switch back to the current buffer
    silent! exec cur_buf.'buffer'
endfunction "}}}

function! dbext#DB_auBufDelete(del_buf_nr) "{{{
    " This function will delete any temporary dictionary files that were 
    " created and disconnect any DBI or ODBC connections
    
    " Save the current buffer to switch back to
    let cur_buf = bufnr("%")
    " Some trickery to make sure this value is considered
    " a number and not a string for use in the index() function.
    let del_buf = a:del_buf_nr + 0

    " This can happen if the buffer does not have a name associated
    " with it, bufnr(expand("<afile">)) can return the current buffer
    if cur_buf == del_buf
        return
    endif

    " Do not let current buffer and syntax highlighting go which may
    " happen when current value of 'bufhidden' is 'delete', 'wipe' etc.
    let cur_bufhidden = &bufhidden
    let cur_syntax    = &syntax
    let cur_filetype  = &filetype

    let idx = index(s:dbext_buffers_with_dict_files, del_buf)
    
    if idx > -1 || exists('g:loaded_dbext_auto')
        setlocal bufhidden=
        " Switch to the buffer being deleted
        silent! exec del_buf.'buffer'

        " If the buffer connection parameters have not been 
        " defaulted, dbext has not been used.
        if s:DB_get("buffer_defaulted") == 1
            " If using the DBI layer, drop any connections which may be active
            if s:DB_get('type') =~ '\<DBI\>\|\<ODBC\>'
                call dbext#DB_disconnect()
            endif

        endif

        " If the buffer number being deleted is in the script
        " variable that lists all buffers that have temporary dictionary
        " files, then remove the temporary dictionary files
        call s:DB_DictionaryDelete( 'Table' )
        call s:DB_DictionaryDelete( 'Procedure' )
        call s:DB_DictionaryDelete( 'View' )

        " Switch back to the current buffer
        silent! exec cur_buf.'buffer'

        " Switch back value of 'bufhidden' and syntax
        if !empty(cur_bufhidden)
            exec "setlocal bufhidden=".cur_bufhidden
            exec "setlocal syntax=".cur_syntax
            exec "setlocal filetype=".cur_filetype
        endif
    endif
endfunction "}}}
"}}}
" Result buffer {{{
function! s:DB_resBufName()
    if s:DB_get('use_sep_result_buffer') == 1
        " Get the file name (no extension)
        let res_buf_name = "Result-" . expand("%:t:r")
    else
        let res_buf_name = "Result"
    endif
    return res_buf_name
endfunction
" }}}
" orientationToggle {{{
function! dbext#DB_orientationToggle(...)
    let sql = s:dbext_prev_sql

    let refresh        = 0
    let curr_bufnr     = s:dbext_prev_bufnr
    let switched_bufnr = s:dbext_prev_bufnr

    " Check to ensure the buffer still exists
    if bufnr(s:dbext_prev_bufnr) > 0
        " If the buffer in that window is still the same buffer
        if winbufnr(s:dbext_prev_winnr) == s:dbext_prev_bufnr
            let refresh = 1
            " Return to original window
            exec s:dbext_prev_winnr."wincmd w"
        else
            " Find another split window which contains this buffer
            if bufwinnr(s:dbext_prev_bufnr) > -1
                let s:dbext_prev_winnr = bufwinnr(s:dbext_prev_bufnr)
                let refresh = 1
                " Return to original window
                exec s:dbext_prev_winnr."wincmd w"
            else
                if &hidden == 1
                    " Return to the original window
                    exec s:dbext_prev_winnr."wincmd w"
                    " Record which buffer we are current editing
                    let switched_bufnr = bufnr('%')
                    " Change the buffer (assuming hidden is set) to the previous
                    " buffer.
                    exec s:dbext_prev_bufnr."buffer"
                    " Refresh the SQL
                    let refresh = 1
                else
                    " If empty, check if they want to leave it empty
                    " of skip this variable
                    let response = confirm("Buffer #:".s:dbext_prev_bufnr.
                                \ " is no longer visible and hidden is not set.".
                                \ " Do you want to execute".
                                \ " this statement using the buffer's".
                                \ " connection parameters from the same window".
                                \ " (buffer #:".bufnr('%').")",
                                \ "&Yes" .
                                \ "\n&No"
                                \ )
                    if response == 1
                        let refresh = 1
                        " Return to original window
                        exec s:dbext_prev_winnr."wincmd w"
                    endif
                endif
            endif
        endif
    else
        call s:DB_warningMsg('dbext:Buffer:'.s:dbext_prev_bufnr.' no longer exists')
        " If empty, check if they want to leave it empty
        " of skip this variable
        let response = confirm("Buffer #:".s:dbext_prev_bufnr.
                    \ " is no longer visible.  Do you want to execute".
                    \ " this statement using the buffer's".
                    \ " connection parameters from the same window".
                    \ " (buffer #:".bufnr('%').")",
                    \ "&Yes" .
                    \ "\n&No"
                    \ )
        if response == 1
            let refresh = 1
            " Return to original window
            exec s:dbext_prev_winnr."wincmd w"
        endif
    endif

    if refresh == 1
        " If the buffer connection parameters have not been 
        " defaulted, dbext has not been used.
        if s:DB_get("buffer_defaulted") == 1
            if s:DB_get('type') =~ '\<DBI\>\|\<ODBC\>'
                let old_orient = s:DB_get('DBI_orientation')
                let new_orient = (old_orient=='horizontal'?'vertical':'horizontal')
                call s:DB_set('DBI_orientation', new_orient)
                " TODO 
                " Ensure this is a DBI or ODBC connection
                " Rerun the SQL command
                call s:DB_runCmd('Orientation Toggle', sql, 'DBI:')
            else
                call s:DB_warningMsg('Changing result set orientation is only available '.
                            \ 'when using the DBI or ODBC interface.')
                return
            endif
        endif
    endif

    if curr_bufnr != switched_bufnr
        " Return to the original window
        exec s:dbext_prev_winnr."wincmd w"
        " Change the buffer (assuming hidden is set) to the previous
        " buffer.
        exec switched_bufnr."buffer"
    endif
endfunction "}}}
" switchPrevBuf {{{
function! dbext#DB_switchPrevBuf()
    let curr_bufnr     = s:dbext_prev_bufnr
    let switched_bufnr = s:dbext_prev_bufnr

    " Check to ensure the buffer still exists
    if bufnr(s:dbext_prev_bufnr) > 0
        " If the buffer in that window is still the same buffer
        if winbufnr(s:dbext_prev_winnr) == s:dbext_prev_bufnr
            " Return to original window
            exec s:dbext_prev_winnr."wincmd w"
            return s:dbext_prev_bufnr
        else
            " Find another split window which contains this buffer
            if bufwinnr(s:dbext_prev_bufnr) > -1
                let s:dbext_prev_winnr = bufwinnr(s:dbext_prev_bufnr)
                " Return to original window
                exec s:dbext_prev_winnr."wincmd w"
                return s:dbext_prev_bufnr
            else
                if &hidden == 1
                    " Return to the original window
                    exec s:dbext_prev_winnr."wincmd w"
                    " Record which buffer we are current editing
                    let switched_bufnr = bufnr('%')
                    " Change the buffer (assuming hidden is set) to the previous
                    " buffer.
                    exec s:dbext_prev_bufnr."buffer"
                    return s:dbext_prev_bufnr
                else
                    " Buffer exists, but hidden is set.
                    " Could not switch to previous buffer.
                    return -2
                endif
            endif
        endif
    else
        " Buffer does not exist.
        " Could not switch to previous buffer.
        return -1
    endif
endfunction "}}}
" runPrevCmd {{{
function! dbext#DB_runPrevCmd(...)
    " If no SQL specified use the current script variable
    if (a:0 > 0) && strlen(a:1) > 0
        let sql = a:1
    else
        let sql = s:dbext_prev_sql
    endif

    let refresh        = 0
    let curr_bufnr     = s:dbext_prev_bufnr
    let switched_bufnr = s:dbext_prev_bufnr

    let rc = dbext#DB_switchPrevBuf()

    " Check to ensure the buffer still exists
    if rc == -2
        " If empty, check if they want to leave it empty
        " of skip this variable
        let response = confirm("Buffer #:".s:dbext_prev_bufnr.
                    \ " is no longer visible and hidden is not set.".
                    \ " Do you want to execute".
                    \ " this statement using the buffer's".
                    \ " connection parameters from the same window".
                    \ " (buffer #:".bufnr('%').")",
                    \ "&Yes" .
                    \ "\n&No"
                    \ )
        if response == 1
            let refresh = 1
            " Return to original window
            exec s:dbext_prev_winnr."wincmd w"
        endif
    elseif rc == -1
        call s:DB_warningMsg('dbext:Buffer:'.s:dbext_prev_bufnr.' no longer exists')
        " If empty, check if they want to leave it empty
        " of skip this variable
        let response = confirm("Buffer #:".s:dbext_prev_bufnr.
                    \ " is no longer visible.  Do you want to execute".
                    \ " this statement using the buffer's".
                    \ " connection parameters from the same window".
                    \ " (buffer #:".bufnr('%').")",
                    \ "&Yes" .
                    \ "\n&No"
                    \ )
        if response == 1
            let refresh = 1
            " Return to original window
            exec s:dbext_prev_winnr."wincmd w"
        endif
    else
        " Switch was successful
        let refresh = 1
    endif

    if refresh == 1
        " Rerun the SQL command
        call dbext#DB_execSql(sql)
    endif

    if curr_bufnr != switched_bufnr
        " Return to the original window
        exec s:dbext_prev_winnr."wincmd w"
        " Change the buffer (assuming hidden is set) to the previous
        " buffer.
        exec switched_bufnr."buffer"
    endif
endfunction 
"}}}
" runCmd {{{
function! s:DB_runCmd(cmd, sql, result)
    let s:dbext_prev_sql   = a:sql
    let l:db_type          = s:DB_get('type')

    " Store current connection parameters
    call s:DB_saveConnParameters()

    let l:display_cmd_line = s:DB_get('display_cmd_line') 

    if l:display_cmd_line == 1
        let cmd_line = "Last command:\n" .
                    \ a:cmd . "\n" .
                    \ "Last SQL:\n" .
                    \ a:sql
        call s:DB_addToResultBuffer(cmd_line, "clear")
    endif

    if s:DB_get('use_result_buffer') == 1
        call s:DB_addToResultBuffer('', "clear")
        if l:display_cmd_line == 1
            call s:DB_addToResultBuffer(cmd_line, "add")
        endif

        if a:result == ""
            let result = system(a:cmd)
        else
            let result = a:result
        endif

        call s:DB_addToResultBuffer(result, "add")

        let dbi_result = 0
        if exists("g:dbext_dbi_result")
            let dbi_result = g:dbext_dbi_result
        endif 

        " If there was an error, show the command just executed
        " for debugging purposes
        if (v:shell_error && l:db_type !~ '\<DBI\>\|\<ODBC\>') ||
                    \ (dbi_result == -1 && l:db_type =~ '\<DBI\>\|\<ODBC\>') 
            let output = "To change connection parameters:\n" .
                        \ ":DBPromptForBufferParameters\n" .
                        \ "Or\n" .
                        \ ":DBSetOption user\|passwd\|dsnname\|srvname\|dbname\|host\|port\|...=<value>\n" .
                        \ ":DBSetOption user=tiger:passwd=scott\n" .
                        \ "Last command(rc=".v:shell_error."):\n" .
                        \ a:cmd . "\n" .
                        \ "Last SQL:\n" .
                        \ a:sql . "\n" 
            call s:DB_addToResultBuffer(output, "add")

            if l:db_type =~ '\<DBI\>\|\<ODBC\>'
                if s:DB_get('DBI_disconnect_onerror') == '1'
                    call dbext#DB_disconnect()
                endif
            endif
        else
            if exists('*DBextPostResult') 
                let res_buf_name   = s:DB_resBufName()
                if s:DB_switchToBuffer(res_buf_name, res_buf_name, 'result_bufnr') == 1
                    " Switch back to the result buffer and execute
                    " the user defined function
                    call DBextPostResult(l:db_type, (s:DB_get('result_bufnr')+0))
                endif
            endif
            if s:DB_get('autoclose') == '1' && s:dbext_result_count <= s:DB_get('autoclose_min_lines')
                " Determine rows affected
                if l:db_type !~ '\<DBI\>\|\<ODBC\>'
                    call s:DB_{l:db_type}_stripHeaderFooter(result)
                endif
                if s:dbext_result_count >= 2
                    if getline(2) !~ '^SQLCode:'
                        call dbext#DB_windowClose(s:DB_resBufName())
                        echon 'dbext: Rows affected:'.g:dbext_rows_affected.' Autoclose enabled, DBSetOption autoclose=0 to disable'
                    endif
                else
                    call dbext#DB_windowClose(s:DB_resBufName())
                    " echon 'dbext: Autoclose enabled, DBSetOption autoclose=0 to disable'
                    echon 'dbext: Rows affected:'.g:dbext_rows_affected.' Autoclose enabled, DBSetOption autoclose=0 to disable'
                endif
            endif
        endif

        " Return to original window
        exec s:dbext_prev_winnr."wincmd w"
    else 
        " Don't use result buffer
        if l:display_cmd_line == 1
            echo cmd_line
        endif

        let dbi_result = 0
        if exists("g:dbext_dbi_result")
            let dbi_result = g:dbext_dbi_result
        endif 

        if a:result == ""
            let result = system(a:cmd)
        elseif a:result == "DBI:"
            perl db_results_variable()
            let result = g:dbext_dbi_result
        else
            let result = a:result
        endif

        " If there was an error, return -1
        " and display a message informing the user.  This is necessary
        " when using sqlComplete, or things slightly fail.
        if (v:shell_error && l:db_type !~ '\<DBI\>\|\<ODBC\>') ||
                    \ (dbi_result == -1 && l:db_type =~ '\<DBI\>\|\<ODBC\>') 
            echo 'dbext:'.result
            let result = '-1'
        endif

        " Reset variable
        let s:dbext_result_count = 0

        return result
    endif

    return
endfunction "}}}
" switchToBuffer {{{
function! s:DB_switchToBuffer(buf_name, buf_file, get_buf_nr_name)
    " Retieve this value before we switch buffers
    let l:buffer_lines = s:DB_get('buffer_lines')

    " Save the current buffer number. dbext will switch back to
    " this buffer when an action is taken.
    let s:dbext_buffer_last       = bufnr('%')
    let s:dbext_buffer_last_winnr = winnr()

    " Do not use bufexists(res_buf_name), since it uses a fully qualified
    " path name to search for the buffer, which in effect opens multiple
    " buffers called "Result" if the files that you are executing the
    " commands from are in different directories.

    " Get the previously stored buffer number
    let res_buf_nr_str  = s:DB_get('result_bufnr')
    let his_buf_nr_str  = s:DB_get('history_bufnr')

    " Get the previously stored buffer number
    let buf_nr_str  = s:DB_get(a:get_buf_nr_name)
    " The buffer number may not have been initialized, so we must
    " handle this case.
    " bufexists takes a numeric argument, so we must add 0 to it
    " to convince Vim we are passing a numeric argument, if not
    " bufexists returns an unexpected value
    let res_buf_nr  = (res_buf_nr_str==''?-1:(res_buf_nr_str+0))
    let his_buf_nr  = (his_buf_nr_str==''?-1:(his_buf_nr_str+0))
    let buf_nr      = (buf_nr_str==''?-1:(buf_nr_str+0))
    let buf_exists  = bufexists(buf_nr)

    if buf_exists != 1
        call s:DB_set(a:get_buf_nr_name, -1)
    endif

    if bufwinnr(buf_nr) == -1
        " if the buffer is not visible, check to see if either
        " the history or result buffer is already open.
        " It if is, simply re-use that window instead of
        " closing and re-opening the split.
        " For some reason there is a visual bell each time
        " this happens.

        let open_new_split = 1
        if bufwinnr(res_buf_nr) > 0
            let open_new_split = 0
            " If the buffer is visible, switch to it
            exec bufwinnr(res_buf_nr) . "wincmd w"
        elseif bufwinnr(his_buf_nr) > 0
            let open_new_split = 0
            exec bufwinnr(his_buf_nr) . "wincmd w"
        endif

        if open_new_split == 1
            if s:DB_getDefault('window_use_horiz') == 1
                if s:DB_getDefault('window_use_bottom') == 1
                    let location = 'botright'
                else
                    let location = 'topleft'
                    " Creating the new window will offset all other
                    " window numbers.  Account for that so we switch
                    " back to the correct window.
                    let s:dbext_prev_winnr = s:dbext_prev_winnr + 1
                endif
                let win_size = l:buffer_lines
            else
                " Open a horizontally split window. Increase the window size, if
                " needed, to accomodate the new window
                if s:DB_getDefault('window_width') &&
                            \ &columns < (80 + s:DB_getDefault('window_width'))
                    " one extra column is needed to include the vertical split
                    let &columns             = &columns + s:DB_getDefault('window_width') + 1
                endif

                if s:DB_getDefault('window_use_right') == 1
                    " Open the window at the rightmost place
                    let location = 'botright vertical'
                else
                    " Open the window at the leftmost place
                    let location = 'topleft vertical'
                    " Creating the new window will offset all other
                    " window numbers.  Account for that so we switch
                    " back to the correct window.
                    let s:dbext_prev_winnr = s:dbext_prev_winnr + 1
                endif
                let win_size = s:DB_getDefault('window_width')
            endif

            " Special consideration was involved with these sequence
            " of commands.  
            "     First, split the current buffer.
            "     Second, edit a new file.
            "     Third record the buffer number.
            " If a different sequence is followed when the yankring
            " buffer is closed, Vim's alternate buffer is the yanking
            " instead of the original buffer before the yankring 
            " was shown.
            let cmd_mod = ''
            if v:version >= 700
                let cmd_mod = 'keepalt '
            endif
            exec 'silent! ' . cmd_mod . location . ' ' . win_size . 'split ' 
        endif
        " Using :e and hide prevents the alternate buffer
        " from being changed.
        exec ":silent! e " . escape(a:buf_file, ' ')
        " Save buffer id
        call s:DB_set(a:get_buf_nr_name, bufnr('%'))
    else
        " If the buffer is visible, switch to it
        exec bufwinnr(buf_nr) . "wincmd w"
    endif

    return 1
endfunction "}}}
" windowClose {{{
function! dbext#DB_windowClose(buf_name)
    if a:buf_name == '%'
        " The user hit 'q', which is a buffer specific mapping to close
        " the result/history/variable window.  Save the size of the buffer
        " for future use.
        
        " Update the local buffer variables with the current size
        " of the window, when we open it again we will use it's
        " size instead of the default
        call s:DB_set('buffer_lines', winheight(a:buf_name))
        
        " Hide it 
        hide

        if bufwinnr(s:dbext_buffer_last) != -1
            " If the buffer is visible, switch to it
            exec s:dbext_buffer_last_winnr . "wincmd w"
        endif

        return
    endif

    " If the command executed was DBResultsClose this must handle both 
    " cases, Results window and the History window
    
    " Results Window
    let res_buf_name   = s:DB_resBufName()

    " Get the previously stored buffer number
    let buf_nr_str  = s:DB_get('result_bufnr')
    let res_buf_nbr = bufnr(res_buf_name)
    let buf_win_nbr = bufwinnr(res_buf_nbr)
    " The buffer number may not have been initialized, so we must
    " handle this case.
    " bufexists takes a numeric argument, so we must add 0 to it
    " to convince Vim we are passing a numeric argument, if not
    " bufexists returns an unexpected value
    let buf_nr      = (buf_nr_str==''?-1:(buf_nr_str+0))
    let buf_exists  = bufexists(buf_nr)

    if bufwinnr(buf_nr) != -1
        " Update the local buffer variables with the current size
        " of the window, when we open it again we will use it's
        " size instead of the default
        call s:DB_set('buffer_lines', winheight(bufwinnr(buf_nr)))

        " If the buffer is visible, switch to it
        exec bufwinnr(buf_nr) . "wincmd w"

        " Hide it 
        hide

        if bufwinnr(s:dbext_buffer_last) != -1
            " If the buffer is visible, switch to it
            exec s:dbext_buffer_last_winnr . "wincmd w"
        endif

        return
    endif

    " History Window
    " Get the previously stored buffer number
    let buf_nr_str  = s:DB_get('history_bufnr')
    " The buffer number may not have been initialized, so we must
    " handle this case.
    " bufexists takes a numeric argument, so we must add 0 to it
    " to convince Vim we are passing a numeric argument, if not
    " bufexists returns an unexpected value
    let buf_nr      = (buf_nr_str==''?-1:(buf_nr_str+0))

    if bufwinnr(buf_nr) != -1
        " Update the local buffer variables with the current size
        " of the window, when we open it again we will use it's
        " size instead of the default
        call s:DB_set('buffer_lines', winheight(bufwinnr(buf_nr)))

        " If the buffer is visible, switch to it
        exec bufwinnr(buf_nr) . "wincmd w"

        " Hide it 
        hide

        if bufwinnr(s:dbext_buffer_last) != -1
            " If the buffer is visible, switch to it
            exec s:dbext_buffer_last_winnr . "wincmd w"
        endif

    endif
endfunction "}}}
" DB_windowOpen {{{
function! dbext#DB_windowOpen()
    " Store current window number so we can return to it
    " let cur_winnr      = winnr()
    let res_buf_name   = s:DB_resBufName()
    let conn_props     = s:DB_getTitle()
    let dbi_orient     = s:DB_get('DBI_orientation')

    call s:DB_saveSize(res_buf_name)

    " Open buffer in required location
    if s:DB_switchToBuffer(res_buf_name, res_buf_name, 'result_bufnr') == 1
        nnoremap <buffer> <silent> R   :DBResultsRefresh<cr>
        nnoremap <buffer> <silent> O   :DBOrientationToggle<cr>
        nnoremap <buffer> <silent> dd  :call dbext#DB_removeVariable()<CR>
        xnoremap <buffer> <silent> d   :call dbext#DB_removeVariable()<CR>
        " nnoremap <buffer> <silent> dd  :call s:DB_removeVariable()<CR>
        " xnoremap <buffer> <silent> d   :call s:DB_removeVariable()<CR>
        " nnoremap <buffer> <silent> dd  :DBVarRangeAssign!<CR>
        " xnoremap <buffer> <silent> d   :DBVarRangeAssign!<CR>
    endif

    setlocal modified
    " Create a buffer mapping to close this window
    nnoremap <buffer> q                :DBResultsClose<cr>
    nnoremap <buffer> <silent> a       :call <SID>DB_set('autoclose', (s:DB_get('autoclose')==1?0:1))<CR>
    if hasmapto('DB_historyDel')
        try
            silent! unmap <buffer> dd
        catch
        endtry
    endif
    if hasmapto('DB_historyUse')
        try
            silent! unmap <buffer> <2-LeftMouse>
            silent! unmap <buffer> <CR>
        catch
        endtry
    endif
    if hasmapto('DB_removeVariable')
        try
            silent! unmap  <buffer> dd
            silent! xunmap <buffer> d
        catch
        endtry
    endif
endfunction "}}}
" DB_windowResize {{{
function! dbext#DB_windowResize()
    silent! exec 'vertical resize '.
                \ (
                \ s:DB_getDefault('window_use_horiz') !=1 && winwidth('.') > s:DB_getDefault('window_width')
                \ ?(s:DB_getDefault('window_width'))
                \ :(winwidth('.') + s:DB_getDefault('window_increment'))
                \ )
endfunction "}}}
" saveSize {{{
function! s:DB_saveSize(buf_name)
    " The result buffer and the history buffer compete for the same
    " space.  We must record the current size of either buffer so
    " the user does not constantly have to resize the window.

    " Do not use bufexists(res_buf_name), since it uses a fully qualified
    " path name to search for the buffer, which in effect opens multiple
    " buffers called "Result" if the files that you are executing the
    " commands from are in different directories.
    let buf_exists  = bufexists(bufnr(a:buf_name))
    let res_buf_nbr = bufnr(a:buf_name)
    let buf_win_nbr = bufwinnr(res_buf_nbr)

    if buf_win_nbr != -1
        " Update the local buffer variables with the current size
        " of the window, when we open it again we will use it's
        " size instead of the default
        call s:DB_set('buffer_lines', winheight(buf_win_nbr))
        " let s:dbext_buffer_lines = winheight(buf_win_nbr)
    endif
endfunction "}}}
" saveConnParameters {{{
function! s:DB_saveConnParameters()
    for param in s:conn_params_mv
        " Iterate through all connection parameters
        " and store them in script local variables
        call s:DB_set( 'saved_'.param, s:DB_get(param) )
    endfor
endfunction "}}}
" restoreConnParameters {{{
function! s:DB_restoreConnParameters()
    for param in s:conn_params_mv
        " Iterate through all connection parameters
        " and store them in script local variables
        call s:DB_set( param, s:DB_get('saved_'.param) )
    endfor
endfunction "}}}
" addToResultBuffer {{{
function! s:DB_addToResultBuffer(output, do_clear)
    " Store current window number so we can return to it
    " let cur_winnr      = winnr()
    let res_buf_name   = s:DB_resBufName()
    let conn_props     = s:DB_getTitle()
    let dbi_orient     = s:DB_get('DBI_orientation')

    call s:DB_saveSize(res_buf_name)

    " Open buffer in required location
    if s:DB_switchToBuffer(res_buf_name, res_buf_name, 'result_bufnr') == 1
        nnoremap <buffer> <silent> R   :DBResultsRefresh<cr>
        nnoremap <buffer> <silent> O   :DBOrientationToggle<cr>
        nnoremap <buffer> <silent> dd  :call dbext#DB_removeVariable()<CR>
        xnoremap <buffer> <silent> d   :call dbext#DB_removeVariable()<CR>
        " nnoremap <buffer> <silent> dd  :call s:DB_removeVariable()<CR>
        " xnoremap <buffer> <silent> d   :call s:DB_removeVariable()<CR>
        " nnoremap <buffer> <silent> dd  :DBVarRangeAssign!<CR>
        " xnoremap <buffer> <silent> d   :DBVarRangeAssign!<CR>
    endif

    setlocal modified
    " Create a buffer mapping to close this window
    nnoremap <buffer> q                :DBResultsClose<cr>
    nnoremap <buffer> <silent> a       :call <SID>DB_set('autoclose', (s:DB_get('autoclose')==1?0:1))<CR>
    nnoremap <buffer> <silent> <space> :DBResultsToggleResize<cr>
    if hasmapto('DB_historyDel')
        try
            silent! unmap <buffer> dd
        catch
        endtry
    endif
    if hasmapto('DB_historyUse')
        try
            silent! unmap <buffer> <2-LeftMouse>
            silent! unmap <buffer> <CR>
        catch
        endtry
    endif
    " Delete all the lines prior to this run
    if a:do_clear == "clear" 
        %d_
        silent! exec "normal! iConnection: ".conn_props.' at '.strftime("%H:%M")."\<Esc>0"

        " We only clear the results buffer at the start of a command
        " this is a good time to restore the saved connection parameters
        " to the Results buffer so that the user can issue commands
        " within the Results buffer and act on the same database they
        " were originally executing SQL against.
        call s:DB_restoreConnParameters()
    endif

    if strlen(a:output) > 0
        " Add to end of buffer
        silent! exec "normal! G"

        if a:output =~ '^DBI:'
            " let data = strpart(a:output, 4)
            " silent! exec "put = data"
            let cmd = "perl db_print_results('".dbi_orient."')"
            exec cmd
        else
            let g:dbext_rows_affected = 0
            let l:start_of_output = line('$')
            silent! exec "put = a:output"
            let l:end_of_output = line('$')
            " Temporarily set this value as a rough estimate
            " (with low cost) to be refined in DB_runCmd 
            " if the autoclose kicks in.
            let g:dbext_rows_affected = l:end_of_output - l:start_of_output
        endif

    endif

    " Since this is a small window, remove any blanks lines
    silent %g/^\s*$/d
    " Fix the ^M characters, if any
    silent execute "%s/\<C-M>\\+$//e"
    " Dont allow modifications, and do not wrap the text, since
    " the data may be lined up for columns
    setlocal nomodified
    setlocal nowrap
    setlocal noswapfile
    setlocal nonumber
    " Go to top of output
    norm gg
    " Store the line count of the result buffer
    let s:dbext_result_count = line('$')

    " Return to original window
    " exec cur_winnr."wincmd w"
    exec s:dbext_prev_winnr."wincmd w"

    return
endfunction "}}}
" Parsers {{{
function! dbext#DB_parseQuery(query)
    " Reset this per query, the user can choose to stop prompting
    " at any time and this should stop for each of the different
    " options in variable_def
    call s:DB_set("stop_prompt_for_variables", 0)
    call s:DB_set("use_saved_variables", 0)

    call s:DB_sqlVarRemoveTemp()
    if s:DB_sqlVarInit() != 0
        let msg = "dbext: parseQuery could not initialize variables"
        call s:DB_warningMsg(msg)
        return a:query
    endif

    " If the user has not overriden the filetype using DB_setOption 
    " then use the filetype Vim set
    let l:filetype = s:DB_get('filetype')
    if l:filetype == ''
        call s:DB_set('filetype', &filetype)
        let l:filetype = &filetype
    endif

    if matchstr( l:filetype, "sql" ) == "sql"
        " Dont parse the SQL query, since DB_parseHostVariables
        " will pickup the standard host variables for prompting.
        " let query = s:DB_parseSQL(a:query)
        return s:DB_parseHostVariables(a:query)
    elseif matchstr( l:filetype, "java" ) == "java" || 
                \ matchstr( l:filetype, "jsp" ) == "jsp"  || 
                \ matchstr( l:filetype, "html" ) == "html"  || 
                \ matchstr( l:filetype, "javascript" ) == "javascript" 
        let query = s:DB_parseJava(a:query)
        return s:DB_parseHostVariables(query)
    elseif matchstr( l:filetype, "jproperties" ) == "jproperties" 
        let query = s:DB_parseJProperties(a:query)
        return s:DB_parseHostVariables(query)
    elseif matchstr( l:filetype, "perl" ) == "perl"
        " The Perl parser will deal with string concatenation
        let query = s:DB_parsePerl(a:query)
        " Let the SQL parser handle embedded host variables
        return s:DB_parseHostVariables(query)
    elseif matchstr( l:filetype, "php" ) == "php"
        let query = s:DB_parsePHP(a:query)
        return s:DB_parseHostVariables(query)
    elseif matchstr( l:filetype, "vim" ) == "vim"
        let query = s:DB_parseVim(a:query)
        return s:DB_parseHostVariables(query)
    elseif matchstr( l:filetype, "vb" ) == "vb"    ||
           \ matchstr( l:filetype, "basic" ) == "basic"
        let query = s:DB_parseVB(a:query)
        return s:DB_parseHostVariables(query)
    else
        return s:DB_parseHostVariables(a:query)
    endif
    return a:query
endfunction

" Host Variable Prompter {{{
function! s:DB_searchReplace(str, exp_find_str, exp_get_value, count_matches)

    " Check if the user has chosen to "Stop Prompting" for this query
    if s:DB_get("stop_prompt_for_variables") == 1
        return a:str
    endif

    let str = a:str
    let count_nbr = 0
    " Find the string index position of the first match
    let index = match(str, a:exp_find_str)
    while index > -1
        " DEBUGGING
        " This is a useful echo statemen to use inside the debug loop 
        " when using breakadd
        "     echo index matchstr(str, a:exp_find_str, index) var a:exp_find_str "\n" strpart(str, 0, (index-1))

        let count_nbr = count_nbr + 1
        " Retrieve the name of what we found
        " let var = matchstr(str, a:exp_get_value, index)
        let var = matchstr(str, a:exp_find_str, index)

        " Check if this is part of a parameter definition
        "   IN       @variable CHAR(1)
        "   OUT      @variable CHAR(1)
        "   INOUT    @variable CHAR(1)
        "   DECLARE  @variable CHAR(1)
        "   VARIABLE @variable CHAR(1)  -- CREATE VARIABLE @variable
        " Or part of a string
        "   '@variable'
        " Or part of path
        "   /@variable'
        " Or a global variable
        "   SET @@variable = ...
        " Or the definition of a global variable
        "   CREATE VARIABLE variable ...
        " If so, ignore the match
        let inout = matchstr(strpart(str, 0, index), '\(\<\w\+\ze\s*$\|''\ze$\|/\ze$\|@\ze$\)')

        if inout !~? '\(in\|out\|inout\|declare\|set\|variable\|''\|/\|@\)'
            " Check if the variable name is preceeded by a comment character.
            " If so, ignore and continue.
            if strpart(str, 0, (index-1)) !~ '\(--\|\/\/\)\s*$'
                " Check to see if the variable is part of the temporarily
                " stored list of variables to ignore
                if has_key(b:dbext_sqlvar_temp_mv, var)
                    " Ingore match and move on
                    " let index = match(str, a:exp_find_str, index+strlen(var))
                    let index = index + strlen(var) + 1
                else
                    " Prompt for value and continue
                    " let index = index + 1

                    let response = 2
                    " If enabled, default to using saved variables
                    let use_save_vars = (s:DB_get("use_saved_variables")==1?1:2)

                    if has_key(b:dbext_sqlvar_mv, var)
                        let var_val = b:dbext_sqlvar_mv[var]
                        let dialog_msg = "There are previously saved variables which can be used ".
                                    \ "in your SQL.  Should these saved variables be used? "
                        if s:DB_get("use_saved_variables") == 0
                            let use_save_vars = confirm(dialog_msg,
                                                    \ "&Yes" .
                                                    \ "\n&No"
                                                    \ )
                            call s:DB_set("use_saved_variables", use_save_vars)
                        endif
                    endif

                    if use_save_vars == 1 && has_key(b:dbext_sqlvar_mv, var)
                        let var_val = b:dbext_sqlvar_mv[var]
                    else
                        " Prompt the user using the name of the variable
                        let dialog_msg = "Enter value for " . var
                        if a:count_matches == 1
                            " If there is no name (ie ?), then include the
                            " count of what was found so the user can
                            " distinguish between different ?s
                            let dialog_msg = dialog_msg . " number " . count_nbr
                        endif
                        let dialog_msg = dialog_msg . ": "
                        let var_val = s:DB_getInput( 
                                    \ dialog_msg,
                                    \ '',
                                    \ "dbext_cancel"
                                    \ )
                        let response = 2
                        " Ok or Cancel result in an empty string
                        if var_val == "dbext_cancel" 
                            let response = 5
                        elseif var_val == "" 
                            " If empty, check if they want to leave it empty
                            " of skip this variable
                            let response = confirm("Your value is empty!",
                                                    \ "&Skip" .
                                                    \ "\n&Use blank" .
                                                    \ "\nS&top Prompting" .
                                                    \ "\n&Never Prompt" .
                                                    \ "\n&Abort"
                                                    \ )
                        endif
                    endif
                    if response == 1
                        " Skip this match and move on to the next
                        " let index = match(str, a:exp_find_str, index+strlen(var))
                        let index = index + strlen(var) + 1
                    elseif response == 2
                        " Use blank
                        " Replace the variable with what was entered
                        let replace_sub = '\%'.(index+1).'c'.'.\{'.strlen(var).'}'
                        let str = substitute(str, replace_sub, var_val, '')
                        " let index = match(str, a:exp_find_str, index+strlen(var_val))
                        let index = index + strlen(var_val) + 1
                        if a:count_matches != 1 && s:DB_get('variable_remember') == '1'
                            " Add this assignment to the list of remembered 
                            " assignments unless it is question marks as host
                            " variables.
                            call dbext#DB_sqlVarAssignment(0, 'set '.var.' = '.var_val)
                        endif
                    elseif response == 4
                        " Never Prompt
                        call s:DB_set("always_prompt_for_variables", '-1')
                        break
                    elseif response == 5
                        " Abort
                        " If we are aborting, do not execute the SQL statement
                        let str = ""
                        break
                    else
                        " Stop Prompting
                        " Skip all remaining matches
                        call s:DB_set("stop_prompt_for_variables", 1)
                        break
                    endif
                endif
            else
                " Move on to next match
                let index = index + strlen(var) + 1
            endif
        else
            " if inout !~? "'" && s:DB_get('variable_remember') == '1'
            if s:DB_get('variable_remember') == '1'
                " Remember this as only a temporary variable and remove
                " these when a new query begins
                call dbext#DB_sqlVarAssignment(2, 'set '.var.' = '.var)
            endif
            " Skip this match and move on to the next
            " let index = match(str, a:exp_find_str, index+strlen(var)) + 1
            let index = index + strlen(var) + 1
        endif

        " Find next match
        let index = match(str, a:exp_find_str, index)
    endwhile
    return str
endfunction 
function! s:DB_searchReplaceOld(str, exp_find_str, exp_get_value, count_matches)

    " Check if the user has chosen to "Stop Prompting" for this query
    if s:DB_get("stop_prompt_for_variables") == 1
        return a:str
    endif

    let str = a:str
    let count_nbr = 0
    " Find the string index position of the first match
    let index = match(str, a:exp_find_str)
    while index > -1
        let count_nbr = count_nbr + 1
        " Retrieve the name of what we found
        let var = matchstr(str, a:exp_get_value, index)

        " Check if this is part of a parameter definition
        "   IN       @variable CHAR(1)
        "   OUT      @variable CHAR(1)
        "   INOUT    @variable CHAR(1)
        "   DECLARE  @variable CHAR(1)
        " Or part of a string
        "   '@variable'
        " Or part of path
        "   /@variable'
        " Or part of path
        "   /@variable'
        " Or a global variable
        "   SET @@variable = ...
        " If so, ignore the match
        let inout = matchstr(strpart(str, 1, (index-1)), '\(\<\w\+\ze\s*$\|''\ze$\|/\ze$\|@\ze$\)')

        if inout !~? '\(in\|out\|inout\|declare\|set\|''\|/\|@\)'
            " Check to see if the variable is part of the temporarily
            " stored list of variables to ignore
            if has_key(b:dbext_sqlvar_temp_mv, var)
                " Ingore match and move on
                let index = match(str, a:exp_find_str, index+strlen(var))
            else
                " Prompt for value and continue
                let index = index + 1

                let response = 2
                if has_key(b:dbext_sqlvar_mv, var)
                    let var_val = b:dbext_sqlvar_mv[var]
                else
                    " Prompt the user using the name of the variable
                    let dialog_msg = "Enter value for " . var
                    if a:count_matches == 1
                        " If there is no name (ie ?), then include the
                        " count of what was found so the user can
                        " distinguish between different ?s
                        let dialog_msg = dialog_msg . " number " . count_nbr
                    endif
                    let dialog_msg = dialog_msg . ": "
                    let var_val = s:DB_getInput( 
                                \ dialog_msg,
                                \ '',
                                \ "dbext_cancel"
                                \ )
                    let response = 2
                    " Ok or Cancel result in an empty string
                    if var_val == "dbext_cancel" 
                        let response = 5
                    elseif var_val == "" 
                        " If empty, check if they want to leave it empty
                        " of skip this variable
                        let response = confirm("Your value is empty!",
                                                \ "&Skip" .
                                                \ "\n&Use blank" .
                                                \ "\nS&top Prompting" .
                                                \ "\n&Never Prompt" .
                                                \ "\n&Abort"
                                                \ )
                    endif
                endif
                if response == 1
                    " Skip this match and move on to the next
                    let index = match(str, a:exp_find_str, index+strlen(var))
                elseif response == 2
                    " Use blank
                    " Replace the variable with what was entered
                    let replace_sub = '\%'.index.'c'.'.\{'.strlen(var).'}'
                    let str = substitute(str, replace_sub, var_val, '')
                    let index = match(str, a:exp_find_str, index+strlen(var_val))
                    if a:count_matches != 1 && s:DB_get('variable_remember') == '1'
                        " Add this assignment to the list of remembered 
                        " assignments unless it is question marks as host
                        " variables.
                        call dbext#DB_sqlVarAssignment(0, 'set '.var.' = '.var_val)
                    endif
                elseif response == 4
                    " Never Prompt
                    call s:DB_set("always_prompt_for_variables", '-1')
                    break
                elseif response == 5
                    " Abort
                    " If we are aborting, do not execute the SQL statement
                    let str = ""
                    break
                else
                    " Stop Prompting
                    " Skip all remaining matches
                    call s:DB_set("stop_prompt_for_variables",1)
                    break
                endif
            endif
        else
            " if inout !~? "'" && s:DB_get('variable_remember') == '1'
            if s:DB_get('variable_remember') == '1'
                " Remember this as only a temporary variable and remove
                " these when a new query begins
                call dbext#DB_sqlVarAssignment(2, 'set '.var.' = '.var)
            endif
            " Skip this match and move on to the next
            let index = match(str, a:exp_find_str, index+strlen(var))
        endif
    endwhile
    return str
endfunction 
"}}}

" Host Variable Parser {{{
function! s:DB_parseHostVariables(query)
    let query = a:query

    let query = s:DB_removeEmptyLines(query)
    " let query = s:DB_sqlVarSubstitute(query)

    if s:DB_get("always_prompt_for_variables") == -1
        " Never try to parse the query
        return query
    endif

    " If query is a SELECT statement, remove any INTO clauses as long
    " as it is not preceeded by INSERT or MERGE
    " Use an case insensitive comparison
    " For some reason [\n\s]* does not work
    if query =~? '^[\n \t]*select'
        let query = substitute(query, 
                    \ '\c\%(\<\%(insert\|merge\)\s\+\)\@<!\<INTO\>.\{-}\<FROM\>', 
                    \ 'FROM', 'g')
    endif

    " Must default the statements to parse
    let dbext_parse_statements = s:DB_get("parse_statements")
    " Verify the string is in the correct format
    " Strip off any trailing commas
    let dbext_parse_statements =
                \ substitute(dbext_parse_statements, ',$','','')
    " Convert commas to regex ors
    let dbext_parse_statements =
                \ substitute(dbext_parse_statements, '\s*,\s*', '\\|', 'g')

    " Only perform replacements if the first statement is one of the
    " following. We do not want to parse the query if for example
    " we are creating a procedure which often uses declared
    " variables within.
    if query =~? '^[\n\t ]*\('.dbext_parse_statements.'\)'
        " Default response to not search and replace
        let response = 2
        " If the user didn't specify any settings, then use the default
        " variable definitions, otherwise use the users override
        let dbext_variable_def = s:DB_get("variable_def")
        let dbext_variable_def =
                    \ substitute(dbext_variable_def,',\?\s*$',',','')
        " From the list of variable definitions, strip out only
        " the identifiers (ie ? @ $ )
        " ; - begins with a ;
        " . - we want this character
        " .\{-} - do not include following characters
        " \ze - end the match on the previous characters
        " ; - stop at the first ;
        let identifier_list = substitute(','.dbext_variable_def,
                    \ ',\(.\)\(.\{-}\)\ze,', '\1', 'g' )
        " Remove the trailing ;
        let identifier_list = substitute(identifier_list, '\(.*\),\s*$',
                    \ '\1', 'g' )

        if s:DB_get("always_prompt_for_variables") == 1
            let response = 1
        else
            " If the statement has any of the following characters
            " ask if the user wants to be prompted for replacements
            " if query =~? '[?@:$]'
            if query =~? '['.identifier_list.']'
                let response = confirm("Do you want to prompt " .
                            \ "for input variables?"
                            \, "&Yes\n&No\n&Always\nNe&ver\nAbor&t", 1 )
            endif
        endif
        if response == 5
            return ""
        elseif response == 4
            call s:DB_set("always_prompt_for_variables", "-1")
            return query
        elseif response == 3
            call s:DB_set("always_prompt_for_variables", "1")
            return query
        elseif response == 2
            " If the user does not want to parse the query
            " return the query as is
            return query
        endif
        " Process each variable definition, format is as follows:
        " identifier1[wW][qQ];identifier2[wW][qQ];identifier3[wW][qQ];
        let pos = 0
        let var_list = split(s:DB_get("variable_def_regex"), ',')
        
        if !empty(var_list)
            for variable_def in var_list
                " If W is chosen, then the identifier cannot be followed
                " by any word characters.  If this is the case (like with ?s)
                " there is no way to distinguish between which ? you are 
                " prompting for, therefore count the identifier and
                " display this information while prompting.
                let count_matches = 0
                if variable_def =~# '?'
                    let count_matches = 1
                endif
                let retrieve_ident = 1

                let query = s:DB_searchReplace(query, variable_def,
                            \ retrieve_ident, count_matches)
                if query == ""
                    " User has aborted the parsing and does not want
                    " the statement executed
                    break
                endif
            endfor
        endif
    endif
    return query
endfunction
function! s:DB_parseHostVariablesOld(query)
    let query = a:query

    call s:DB_sqlVarRemoveTemp()
    if s:DB_sqlVarInit() != 0
        return -1
    endif
    let query = s:DB_removeEmptyLines(query)
    " let query = s:DB_sqlVarSubstitute(query)

    if s:DB_get("always_prompt_for_variables") == -1
        " Never try to parse the query
        return query
    endif

    " If query is a SELECT statement, remove any INTO clauses as long
    " as it is not preceeded by INSERT or MERGE
    " Use an case insensitive comparison
    " For some reason [\n\s]* does not work
    if query =~? '^[\n \t]*select'
        let query = substitute(query, 
                    \ '\c\%(\<\%(insert\|merge\)\s\+\)\@<!\<INTO\>.\{-}\<FROM\>', 
                    \ 'FROM', 'g')
    endif

    " Must default the statements to parse
    let dbext_parse_statements = s:DB_get("parse_statements")
    " Verify the string is in the correct format
    " Strip off any trailing commas
    let dbext_parse_statements =
                \ substitute(dbext_parse_statements, ',$','','')
    " Convert commas to regex ors
    let dbext_parse_statements =
                \ substitute(dbext_parse_statements, '\s*,\s*', '\\|', 'g')

    " Only perform replacements if the first statement is one of the
    " following. We do not want to parse the query if for example
    " we are creating a procedure which often uses declared
    " variables within.
    if query =~? '^[\n\t ]*\('.dbext_parse_statements.'\)'
        " Default response to no search and replace
        let response = 2
        " If the user didn't specify any settings, then use the default
        " variable definitions, otherwise use the users override
        let dbext_variable_def = s:DB_get("variable_def")
        let dbext_variable_def =
                    \ substitute(dbext_variable_def,',\?\s*$',',','')
        " From the list of variable definitions, strip out only
        " the identifiers (ie ? @ $ )
        " ; - begins with a ;
        " . - we want this character
        " .\{-} - do not include following characters
        " \ze - end the match on the previous characters
        " ; - stop at the first ;
        let identifier_list = substitute(','.dbext_variable_def,
                    \ ',\(.\)\(.\{-}\)\ze,', '\1', 'g' )
        " Remove the trailing ;
        let identifier_list = substitute(identifier_list, '\(.*\),\s*$',
                    \ '\1', 'g' )

        if s:DB_get("always_prompt_for_variables") == 1
            let response = 1
        else
            " If the statement has any of the following characters
            " ask if the user wants to be prompted for replacements
            " if query =~? '[?@:$]'
            if query =~? '['.identifier_list.']'
                let response = confirm("Do you want to prompt " .
                            \ "for input variables?"
                            \, "&Yes\n&No\n&Always\nNe&ver\nAbor&t", 1 )
            endif
        endif
        if response == 5
            return ""
        elseif response == 4
            call s:DB_set("always_prompt_for_variables", "-1")
            return query
        elseif response == 3
            call s:DB_set("always_prompt_for_variables", "1")
            return query
        elseif response == 2
            " If the user does not want to parse the query
            " return the query as is
            return query
        endif
        " Process each variable definition, format is as follows:
        " identifier1[wW][qQ];identifier2[wW][qQ];identifier3[wW][qQ];
        let pos = 0
        let var_list = split(s:DB_get("variable_def"), ',')
        
        if !empty(var_list)
            for variable_def in var_list
                " Extract the identifier, use the greedy nature of regex.
                " Allow them to specify more than a single character for the
                " search. We must assume they follow the correct format
                " though and the criteria ends with a WQ; (case insensitive)
                let until_str = ''
                let identifier = matchstr(variable_def,'\zs\(.*\)\ze[wW][qQ]$')
                " let identifier = substitute(variable_def,'\(.*\)[wWu][qQ]$','\1','')
                let following_word_option = 
                            \ matchstr(variable_def, '.*\zs[wW]\ze[qQ]$')
                            " substitute(variable_def, '.*\([wW]\)[qQ]$', '\1', '')
                let quotes_option = 
                            \ matchstr(variable_def, '.*\zs[qQ]\ze$')
                            " substitute(variable_def, '.*\([qQ]\)$', '\1', '')
                if identifier == ''
                    let until_str = 
                            \ matchstr(variable_def, '.*[u]\zs.\+\ze$')
                            " substitute(variable_def, '.*[u]\(.\+\)$', '\1', '')
                    let identifier = 
                            \ matchstr(variable_def, '\zs.*\ze[u]\(.\+\)$')
                endif

                " Validation checks
                if strlen(identifier) != 0
                    " Make sure no word characters preceed the identifier
                    let no_preceed_word = '\(\w\)\@<!'
                else
                    let msg = "dbext: Variable Def: Invalid identifier[" .
                                \ variable_def . "]"
                    call s:DB_warningMsg(msg)
                    return query
                endif
                if until_str != ''
                    " Prompt up until the following 
                    let following_word = ''
                    let retrieve_ident = identifier . following_word
                elseif following_word_option ==# 'w'
                    " w - MUST have word characters after it
                    let following_word = '\w\+'
                    let retrieve_ident = identifier . following_word
                elseif following_word_option ==# 'W'
                    " W - CANNOT have any word characters after it
                    let following_word = '\(\w\)\@<!'
                    let retrieve_ident = identifier
                else
                    let msg = "dbext: Variable Def: " .
                                \ "Invalid following word indicator[" .
                                \ variable_def . "]"
                    call s:DB_warningMsg(msg)
                    return query
                endif
                if until_str != ''
                    " Prompt up until the following 
                    let quotes = ''
                elseif quotes_option ==# 'q'
                    " q - quotes do not matter
                    let quotes = ''
                elseif quotes_option ==# 'Q'
                    " Q - CANNOT be surrounded in quotes
                    let quotes = "'".'\@<!'
                else
                    let msg = "dbext: Variable Def: Invalid quotes indicator[" .
                                \ variable_def . "]"
                    call s:DB_warningMsg(msg)
                    return query
                endif


                " If W is chosen, then the identifier cannot be followed
                " by any word characters.  If this is the case (like with ?s)
                " there is no way to distinguish between which ? you are 
                " prompting for, therefore count the identifier and
                " display this information while prompting.
                let count_matches = 0
                if variable_def =~# 'W[qQ]$'
                    let count_matches = 1
                endif

                if until_str != ''
                    let srch_cond      = escape(identifier, '\\/.*$^~[]') .
                                \ '.\{-}' .
                                \ escape(until_str, '\\/.*$^~[]')
                    let retrieve_ident = srch_cond
                else
                    let srch_cond = quotes . no_preceed_word .
                            \ identifier . following_word . quotes
                endif

                let query = s:DB_searchReplace(query, srch_cond,
                            \ retrieve_ident, count_matches)
                if query == ""
                    " User has aborted the parsing and does not want
                    " the statement executed
                    break
                endif
            endfor
        endif
    endif
    return query
endfunction
"}}}

" SQL Parser {{{
function! s:DB_parseSQL(query)
    let query = a:query

    " If query is not a select statement, dont both parsing at this point
    if query !~? '^[\n \t]*select'
        return query
    endif

    " Remove any newline characters
    let query = substitute(query, "\n", ' ', 'g')
    " Do not strip off beginning and closing quotes for SQL statements
    " let query = substitute(query, 
    "             \ '\%(^[\t ' . "']*" . '\)\?', 
    "             \ '', 
    "             \ ''
    "             \ )
    " let query = substitute(query, 
    "             \ "[ ';]" . '\+$', 
    "             \ '', 
    "             \ ''
    "             \ )


    " If strings are concatenated over multiple lines, since they are
    " joined now, remove the concatenation
    "    'select ' + ' * from ' + ' some_table ';
    "    'select ' || ' * from ' || ' some_table ';
    let query = substitute(query, 
                \ '\s*' . "'" . '\s*\%(+\|||\)\s*' . "'" . '\s*', 
                \ ' ', 
                \ 'g'
                \ )

    " Prompt for the variables which are part of
    " string concentations like this:
    "   'SELECT * FROM ' + prefix+'product'
    " In this case db_property('Name') should not be prompted for
    " since it is a valid function call with no host variables.
    "   'SELECT * FROM ' + db_property('Name') +'product'
    let var_expr = "'".'\s*+\%(\|||\)\s*\(.\{-}\)\s*\%(+\|||\|;\|$\)\s*'."'".'\?'

    "  "'".\s*             - Single quote followed any space 
    "  \%(\|||\)\s*        - A plus sign or || and any space
    "  \(.\{-}\)           - The variable / obj / method
    "  \%(\|||\|;\|$\)\s*  - A plus sign or || or ; or end of line and any space
    "  "'".'\?'            - Optional sinqle quote following

    " This has been turned off temporarily since if the strings contain
    " host variables, they will be picked up by DB_parseHostVariables.
    " let query = s:DB_searchReplace(query, var_expr, var_expr, 0)

    return query
endfunction
"}}}

" PHP Parser {{{
function! s:DB_parsePHP(query)
    let query = a:query
    " Remove any newline characters
    let query = substitute(query, "\n", ' ', 'g')
    " Since PHP can use either single or double quotes
    " the queries below are more difficult concatenating 
    " different strings together.

    " Strip off beginning and closing quotes
    " These can be single or double quotes
    let query = substitute(query, 
                \ '\%(^[\t "'."'".']*\)\?', 
                \ '', 
                \ ''
                \ )
    " For the ending quotes, remove at most 1
    let query = substitute(query, 
                \ '["'."'".']\?\s*\(;\|\.\)\?\s*$', 
                \ '', 
                \ ''
                \ )
                " \ '[ "'."'".';]\+$', 

    " Since strings are enclosed in double quotes ("), they can be escaped
    " with a backslash, we must replace these as well.
    "     "select \"name\", col2  "
    let query = substitute(query, 
                \ '\\"', 
                \ '"', 
                \ 'g'
                \ )

    " Strip off beginning and closing quotes
    " The ending quote can be any of the following:
    "      something "
    "      something ",
    "      something ',
    "      something " +
    "      something ' .
    "      something " .
    "      something " ;
    " let query = substitute(query, 
    "             \ '\%(^[\t "'."'".']*\)\?', 
    "             \ '', 
    "             \ ''
    "             \ )
    " let query = substitute(query, 
    "             \ '[ "'."'".';.+]\+$', 
    "             \ '', 
    "             \ ''
    "             \ )

    " If strings are concatenated over multiple lines, since they are
    " joined now, remove the concatenation
    " Do not remove the ending semi-colon
    "    "select " + " * from " + " some_table ";
    "    "select " . " * from " . " some_table ";
    "    'select ' . ' * from ' . ' some_table ';
    let query = substitute(query, 
                \ '\s*["'."'".']\s*\(+\|\.\)\(\s*["'."'".']\s*\)', 
                \ ' ', 
                \ 'g'
                \ )
                " \ '\s*["'."'".']\s*\(+\|\.\)\(\s*["'."'".']\s*\|;\)', 

    " Prompt for the variables which are part of
    " string concentations like this:
    "   "SELECT * FROM ".$prefix."product"
    "   'SELECT * FROM '.$prefix.'product'
    let var_expr = '["'."'".']\s*\.\s*\(\$.\{-}\)\(\[.\{-}\]\)\?\(\.\s*["'."'".']\|\s*;\?\s*$\)'
    "  ["']\s*          - Double quote followed any space 
    "  \.\s*            - A period and any space
    "  \(\$.\{-}\)      - The variable / obj / method
    "  \(\[.\{-}\]\)\?  - Optional [...]
    "  \(               - One of the following
    "     \.\s*["']     - A period followed by any space followed by a double quote
    "     \|            - or
    "     \s*;\?\s*$    - An optional semicolon or end of line
    "  \)               - End of choice
    let query = s:DB_searchReplace(query, var_expr, var_expr, 0)

    " This next one will handle both {$pkey_name} and $id
    " select * from users where {$pkey_name}_id=$id;
    " select * from users where {$pkey_name[3]}_id=$id;
    let var_expr = '{\?\$\h\w*\(\[.\{-}\]\)\?}\?'
    "  {\?             - Open curly is optional
    "  \$\h\w*         - $ sign, followed by a head of a word and more
    "  \(\[.\{-}\]\)\? - Optionally followed by [...]
    "  }\?             - Close curly is optional
    let query = s:DB_searchReplace(query, var_expr, var_expr, 0)

    return query
endfunction
"}}}

" Java, JSP, JavaScript Parser {{{
function! s:DB_parseJava(query)
    let query = a:query
    " Remove any newline characters
    let query = substitute(query, "\n", ' ', 'g')
    
    " Since strings are enclosed in double quotes ("), they can be escaped
    " with a backslash, we must replace these as well.
    "     "select \"name\", col2  "
    let query = substitute(query, 
                \ '\\"', 
                \ '"', 
                \ 'g'
                \ )

    " Strip off beginning and closing quotes
    " The ending quote can be any of the following:
    "      something "
    "      something ",
    "      something " +
    "      something " ;
    let query = substitute(query, 
                \ '\%(^[\t "]*\)\?', 
                \ '', 
                \ ''
                \ )
    let query = substitute(query, 
                \ '[ ";,+]\+$', 
                \ '', 
                \ ''
                \ )
    " If strings are concatenated over multiple lines, since they are
    " joined now, remove the concatenation
    "    "select " + " * from " + " some_table ";
    let query = substitute(query, 
                \ '\s*"\s*+\s*"\s*', 
                \ ' ', 
                \ 'g'
                \ )

    " Java uses \n to signify newlines.  We must replace these will
    " spaces.
    let query = substitute(query, 
                \ '\\n', 
                \ ' ', 
                \ 'g'
                \ )

    " Prompt for the variables which are part of
    " string concentations like this:
    "   "SELECT * FROM " + prefix+"product"
    "   "SELECT * FROM " + obj.method() +"product"
    let var_expr = '"\s*+\s*\(.\{-}\)\s*+\s*"'
    "  "\s*       - Double quote followed any space 
    "  +\s*       - A plus sign and any space
    "  \(.\{-}\)  - The variable / obj / method
    "  \s*+       - Any space and a plus sign
    "  \s*"       - Any space followed by a double quote
    let query = s:DB_searchReplace(query, var_expr, var_expr, 0)

    return query
endfunction
"}}}

" Java Properties (jproperties) Parser {{{
function! s:DB_parseJProperties(query)
    let query = a:query

    " Property files have the format:
    " NAME = VALUE
    "
    " If a line can be continue on the next line
    " using a continuation character "\"
    "
    " Remove any line continuation and newline characters
    let query = substitute(a:query, '\%(\s*\\\s*\)\?'."\n", ' ', 'g')

    return query
endfunction
"}}}

" Vim Parser {{{
function! s:DB_parseVim(query)
    let query = a:query
    " Remove any newline characters
    let query = substitute(query, "\n", ' ', 'g')
    " Strip off beginning and closing quotes
    let query = substitute(query, 
                \ '\%(^[\t "]*\)\?', 
                \ '', 
                \ ''
                \ )
    let query = substitute(query, 
                \ '[ ";]\+$', 
                \ '', 
                \ ''
                \ )
    " If strings are concatenated over multiple lines, since they are
    " joined now, remove the concatenation
    "    "select " . " * from " . " some_table ";
    "    \ "select " .
    "    \ " * from "
    "    \ . " some_table ";
    let query = substitute(query, 
                \ '\\\?\s*"\s*\\\?\s*\.\s*\\\?\s*"\s*', 
                \ ' ', 
                \ 'g'
                \ )

    " Prompt for the variables which are part of
    " string concentations like this:
    "   "SELECT * FROM " . method() ."product"
    let var_expr = '"\s*\\\?\s*\.\s*\\\?\s*\(.\{-}\)\s*\s*\\\?\.\s*\\\?\s*"'
    "  "\s*       - Double quote followed any space 
    "  \\\?       - A backslash (optional)
    "  \s*        - Any space
    "  \.         - A period
    "  \s*        - Any space
    "  \(.\{-}\)  - The variable / obj / method
    "  \s*        - Any space
    "  \.         - A period
    "  \s*"       - Any space followed by a double quote
    let query = s:DB_searchReplace(query, var_expr, var_expr, 0)

    return query
endfunction
"}}}

" Perl Parser {{{
function! s:DB_parsePerl(query)
    let query = a:query
    " Remove any newline characters
    let query = substitute(query, "\n", ' ', 'g')
    " Strip off beginning and closing quotes
    let query = substitute(query, 
                \ '\%(^[\t "]*\)\?', 
                \ '', 
                \ ''
                \ )
    let query = substitute(query, 
                \ '[ ";]\+$', 
                \ '', 
                \ ''
                \ )
    " If strings are concatenated over multiple lines, since they are
    " joined now, remove the concatenation
    "    "select " + " * from " + " some_table ";
    "    "select " . " * from " . " some_table ";
    let query = substitute(query, 
                \ '\s*"\s*\(+\|\.\)\s*"\s*', 
                \ ' ', 
                \ 'g'
                \ )

    " Prompt for the variables which are part of
    " string concentations like this:
    "   "SELECT * FROM " + $prefix+"product"
    "   "SELECT * FROM " + $obj.method() +"product"
    "   "SELECT * FROM " . method() ."product"
    "   "SELECT * FROM product WHERE c1 = $mycol AND c2 = ".$cols[2];
    let var_expr = '"\s*\(+\|\.\)\s*\(.\{-}\)\s*\(\(\(+\|\.\)\s*"\)\|;\|$\)'
    "  "\s*       - Double quote followed any space 
    "  \(+\|\.\)  - A plus sign or period
    "  \s*        - Any space
    "  \(.\{-}\)  - The variable / obj / method
    "  \s*        - Any space
    "  \(+\|\.\)  - A plus sign or period
    "  \s*"       - Any space followed by a double quote
    let query = s:DB_searchReplace(query, var_expr, var_expr, 0)

    " Prompt for $ variables 
    "   "SELECT * FROM product WHERE c1 = $mycol "
    let var_expr = '\(\$\w\+\)'
    "  \(\$\w\+\)  - The variable / obj / method beginning with a $
    let query = s:DB_searchReplace(query, var_expr, var_expr, 0)

    return query
endfunction
"}}}

" VB Parser, Garrison Yu {{{
function! s:DB_parseVB(query)

    " Join all line continuations by removing the ending "_"
    let a_query = substitute(a:query, " _[\r\n]\\+\\s*", "","g")

    " Get the string part of the vb query and remove the beginning
    " and closing quotes
    let query = ""
    let isPureSql = 1
    for line in split(a_query, "[\r\n]\\+")

        let t = matchstr(line, '\(\("\([^"\\]\|\\.\)*"[^"'']*\)\+\)')
        let t = substitute(t, '^\s*"', '\1',"")
        let t = substitute(t, '"\s*$', "","")
        if t != ""
            let query = query . "\n" . t
            let isPureSql = 0
        endif
    endfor

    " Is not executing in vb environment
    if isPureSql == 1
        return a:query
    endif
    
    " Since strings are enclosed in double quotes ("), they can be escaped
    " with a backslash, we must replace these as well.
    "     "select \"name\", col2  "
    let query = substitute(query, '\\"', '"', 'g')

    " If strings are concatenated over multiple lines, since they are
    " joined now, remove the concatenation
    "    "select " + " * from " + " some_table ";
    "    "select " & " * from " & " some_table ";
    let query = substitute(query, '"\s*[+&]\s*"', ' ', 'g')
    let query = substitute(query, '\s*\([+&]\)\s*', '\1', 'g')

    " remove \n
    let query = substitute(query, "[\r\n]\\+", ' ', 'g')

    " Prompt for the variables which are part of
    " string concentations like this:
    "   "SELECT * FROM " + prefix+"product"
    "   "SELECT * FROM " + obj.method() +"product"
    "call inputdialog(query)
    let var_expr = '\s*[+&]\s*\(.\{-}\)\s*[+&]\s*'
    let var_expr_q = '"' . var_expr . '"'
    "  "\s*       - Double quote followed any space 
    "  [+&]\s*    - A plus sign and any space
    "  \(.\{-}\)  - The variable / obj / method
    "  \s*[+&]    - Any space and a plus sign
    "  \s*"       - Any space followed by a double quote

    let query = s:DB_searchReplace(query, var_expr, var_expr, 0)

    "call inputdialog(query)
    return query
endfunction
"}}}


" Profile Parser {{{
function! s:DB_parseProfile(value)

    " Shortcut
    if a:value =~ '^\s*$'
        return 0
    endif

    " Check for non-word characters to make sure the profile
    " name was parsed correctly
    if match(a:value, '\W') > -1
        let rc = -1
        call s:DB_warningMsg('dbext: Invalid profile name: ' . a:value) 
        return -1
    endif

    let profile_name = "g:dbext_default_profile_" . a:value

    if exists(profile_name)
        let profile_value = g:dbext_default_profile_{a:value}
    else
        let rc = -1
        call s:DB_warningMsg('dbext: ' . profile_name 
                                \ . ' does not exist' )
        return -1
    endif

    " Reset all connection parameters to blanks since a 
    " profile should set everything required
    let no_defaults = 0
    let rc = s:DB_resetBufferParameters(no_defaults)

    if profile_value =~? '\<profile\>'
        let rc = -1
        call s:DB_warningMsg('dbext: Profiles cannot be nested' )
        return -1
    endif

    let rc = dbext#DB_setMultipleOptions(profile_value)

    return rc
endfunction

" SQL Variables Management {{{
"
" The purpose of this sub-code is to add buffer variables specially 
" for SQL variables.  Features:
"   1. Use the following command to add/remove variables
"      # set xxx = 'yyy'
"      # unset xxx = 'yyy'
"   2. Once the variables are set, the variables will be used before 
"      further processing the sql queries.
"
function! s:DB_sqlVarInit()
    " If the buffer connection parameters are not initialized
    " the wrong values may be pulled for the value of the variable 
    " specifically, the statement terminator may be included in the 
    " value.
    let use_defaults = 1
    if s:DB_get("buffer_defaulted") != 1
        let rc = s:DB_resetBufferParameters(use_defaults)
        if rc == -1
            call s:DB_warningMsg( 
                        \ "dbext:A valid database type must ".
                        \ "be chosen first" 
                        \ )
            return rc
        endif
    endif

    " Init the sql var dictionary
    if !exists("b:dbext_sqlvar_mv")
        let b:dbext_sqlvar_mv = {}
    endif
    if !exists("b:dbext_sqlvar_temp_mv")
        let b:dbext_sqlvar_temp_mv = {}
    endif

    return 0
endfunction

function! s:DB_sqlVarRemoveTemp()
    " Temporary variables must be cleaned up for each new
    " statement executing.
    if exists("b:dbext_sqlvar_temp_mv")
        unlet b:dbext_sqlvar_temp_mv
    endif

    return 0
endfunction

function! s:DB_sqlVarSet(name, value, temporary)
    " Store a var in buffer variable for any following sql queries
    if s:DB_sqlVarInit() != 0
        return -1
    endif

    try
        if a:temporary == 0
            let b:dbext_sqlvar_mv[a:name] = a:value
        else
            let b:dbext_sqlvar_temp_mv[a:name] = a:value
        endif
    catch
        call s:DB_warningMsg('Failed to set:'.a:name.' ==> |'.a:value.'|')
    endtry

endfunction

function! dbext#DB_sqlVarAssignment(drop_var, stmt)
    " Execute the user provided assignment statement
    "
    " drop_var can 3 values
    "     0 - standard variable
    "     1 - drop the variable
    "     2 - store a temporary variable (only for the query)
    "
    " A drop_var = 2 can only happen while parsing a query for
    " host variables from DB_searchReplace()
    if s:DB_sqlVarInit() != 0
        return -1
    endif

    let stmt = a:stmt
    let matches = matchlist(stmt,'\s*set\s\+\(.\{-}\)\s*=\s*\(.\{-\}\)'.
                \ '\%('.dbext#DB_getWType("cmd_terminator").'\)\?\s*$'
                \ )
    if ! empty(matches)
        let name = matches[1]
        let value = matches[2]

        if name != '' 
            if value != '' && a:drop_var != 1
                " Set the variable
                call s:DB_sqlVarSet(name, value, a:drop_var)
            else
                " Remove the variable
                if has_key(b:dbext_sqlvar_mv, name)
                    call remove(b:dbext_sqlvar_mv, name)
                endif
            endif
        else
            call s:DB_warningMsg('Failed to execute:|'.stmt.'|'.name.'|'.value.'|')
        endif
    else
        let matches = matchlist(stmt,'\s*unset\s\+\(.\{-}\).*')
        if empty(matches)
            call s:DB_warningMsg('dbext: Unknown statement:|'.stmt.'|')
            return
        endif
        if matches[1] != "" && exists("b:dbext_sqlvar_mv") && has_key(b:dbext_sqlvar_mv, matches[1])
            unlet b:dbext_sqlvar_mv[matches[1]]
        else
            call s:DB_warningMsg('Failed to find var:|'.matches[1].'|')
        endif

    endif
endfunction

function! dbext#DB_sqlVarRangeAssignment(remove_var) range
    for lineNum in range(a:firstline, a:lastline)
        let line = getline(lineNum)
        if line !~ "^\s*$"
            call dbext#DB_sqlVarAssignment(a:remove_var, line)
        endif
    endfor
endfunction

function! dbext#DB_removeVariable() range
    let curr_bufnr     = s:dbext_prev_bufnr
    let switched_bufnr = s:dbext_prev_bufnr

    let lines          = []
    for lineNum in range(a:firstline, a:lastline)
        let line = getline(lineNum)
        if line !~ "^\s*$"
            call add(lines, line)
        endif
    endfor

    let rc = dbext#DB_switchPrevBuf()

    " Check to ensure the buffer still exists
    if rc > 0
        for line in lines
            call dbext#DB_sqlVarAssignment(1, line)
        endfor
    endif

    DBResultsClose
endfunction 

function! s:DB_removeEmptyLines(sql)
    " let sql = s:DB_stripLeadFollowSpaceLines(a:sql)
    let sql = substitute(a:sql, '[\n\r]\+\(\s*[\n\r]\*\)*\s*[\n\r]\+', '\n', 'g')

    return sql
endfunction

function! s:DB_sqlVarSubstitute(sql)
    " Substitute sql vars in the given stmt
    if s:DB_sqlVarInit() != 0
        return -1
    endif
    let sql = a:sql

    for [k,v] in items(b:dbext_sqlvar_mv)
        " let sql = substitute(sql, '[:@]'.k, v, 'g')
        let sql = substitute(sql, k, v, 'g')
    endfor

    for [k,v] in items(b:dbext_sqlvar_temp_mv)
        " let sql = substitute(sql, '[:@]'.k, v, 'g')
        let sql = substitute(sql, k, v, 'g')
    endfor

    return sql
endfunction

function! dbext#DB_sqlVarList(...)
    " Record current buffer to return to the correct one
    let s:dbext_prev_winnr = winnr()
    let s:dbext_prev_bufnr = bufnr('%')

    if s:DB_sqlVarInit() != 0
        return -1
    endif

    let var_list = 
                \ "------------------------\n" .
                \ "** Variable List **\n" .
                \ "------------------------"
    for [k,v] in items(b:dbext_sqlvar_mv)
        let var_list = var_list . 
                    \ "\nset ".k." = ".v
    endfor

    call s:DB_addToResultBuffer(var_list, "clear")

    return ""
endfunction
"}}}
" History {{{
function! s:DB_historyAdd(sql)

    " Record current buffer to return to the correct one
    let s:dbext_prev_winnr = winnr()
    let s:dbext_prev_bufnr = bufnr('%')
 
    let max_entry = s:DB_get('history_max_entry')
    if max_entry != 0 && strlen(a:sql) > max_entry
        return
    endif

    let sql = substitute(a:sql, "\n", '@@@', 'g')
    " Strip leading and trailing markers
    let sql = substitute (sql, '^\(@@@\)*\(.\{-}\)\(@@@\)*$', '\2', 'g')
    call s:DB_historyOpen()

    " Go to top of file and search the the same string
    setlocal noreadonly
    exec "normal! gg"
    " Remove any duplicate entries
    exec 'silent! %g/^\d\+\.\s\+'.escape(sql, '\\/.*$^~[]').'\s*$/d'
    1put ='1. '.sql
    " Renumber existing entries
    exec 'silent! %s/^\d\+\ze\.\s\+/\=line(".")-1'

    exec "normal! 2gg"
    " Save the history file
    call s:DB_historySave(1)

    let res_buf_name   = s:DB_resBufName()
    call dbext#DB_windowClose(s:DB_resBufName())

    " Return to original window
    " exec cur_winnr."wincmd w"
    exec s:dbext_prev_winnr."wincmd w"

endfunction 

function! s:DB_historyUse(line)
    let i = matchstr(getline(a:line), '^\d\+')

    if i !~ '\d'
        " call s:DB_warningMsg('dbext:Invalid choice:'.getline(a:line))
        return
    endif

    let sql = matchstr(getline("."), '^\d\+\.\s*\zs.*')
    let sql = substitute(sql, '@@@', "\n", 'g')

    call dbext#DB_runPrevCmd(sql)
endfunction 

function! s:DB_historyDel(line)
    let i = matchstr(getline(a:line), '^\d\+')

    if i !~ '\d'
        " call s:DB_warningMsg('dbext:Invalid choice:'.getline(a:line))
        return
    endif

    set noreadonly
    exec 'silent! g/^'.i.'\./d'
    " Renumber existing entries
    exec 'silent! %s/^\d\+\ze\.\s\+/\=line(".")-1'
    exec "normal! 2gg"
    call s:DB_historySave(0)
endfunction 

function! dbext#DB_historyList()
    let s:dbext_prev_winnr = winnr()
    let s:dbext_prev_bufnr = bufnr('%')

    call s:DB_historyOpen()

    " Create a mapping to act upon the history
    nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>DB_historyUse(line("."))<CR>
    nnoremap <buffer> <silent> <CR>          :call <SID>DB_historyUse(line("."))<CR>
    nnoremap <buffer> <silent> dd            :call <SID>DB_historyDel(line("."))<CR>
    nnoremap <buffer> <silent> a             :call <SID>DB_set('autoclose', (s:DB_get('autoclose')==1?0:1))<CR>
    " Create a buffer mapping to close this window
    nnoremap <buffer> q                      :DBResultsClose<cr>
    nnoremap <buffer> <silent> <space>       :DBResultsToggleResize<cr>
    
    if hasmapto('DB_removeVariable')
        try
            silent! unmap  <buffer> dd
            silent! xunmap <buffer> d
        catch
        endtry
    endif
    if hasmapto('DBResultsRefresh')
        try
            silent! unmap <buffer> R
        catch
        endtry
    endif
    if hasmapto('DBOrientationToggle')
        try
            silent! unmap <buffer> O
        catch
        endtry
    endif
    " Go to top of output
    norm 2gg
endfunction 

function! s:DB_historyOpen()
    let res_buf_name   = s:DB_resBufName()
    call s:DB_saveSize(s:DB_get('history_bufname'))

    " Prevent the alternate buffer (<C-^>) from being set to this
    " temporary file
    let l:old_cpoptions   = &cpoptions
    let l:old_eventignore = &eventignore
    setlocal cpo-=A
    setlocal eventignore=all

    " Now display the history window
    if s:DB_switchToBuffer(s:DB_get('history_bufname'), s:DB_get('history_file'), 'history_bufnr') > 0
        if line("$") == 1 && getline(1) == ''
            " New buffer, check to ensure it has something in it
            0put ='dbext history, <enter> or dbl-click ' .
                        \ 'to execute, or [q] to quit (history size:' .  
                        \ s:DB_get('history_size') .
                        \ ')'
            exec "g/^\s*$/d"
            " This will save and hide the buffer
            call s:DB_historySave(0)
        endif
    endif

    " Restore previous cpoptions
    let &cpoptions   = l:old_cpoptions
    let &eventignore = l:old_eventignore

    " Do setup always, just in case.
    setlocal bufhidden=hide
    setlocal nobuflisted
    setlocal noswapfile
    setlocal nowrap
    setlocal nonumber
    setlocal nomodified
    setlocal readonly
    " Reload buffer automatically if it has changed outside of
    " this Vim session
    setlocal autoread
endfunction 

function! s:DB_historySave(auto_hide)
    " Do setup always, just in case.
    " setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal nobuflisted
    setlocal noswapfile
    setlocal noreadonly

    " Delete entries past the size limit
    let size = s:DB_get('history_size') + 2
    " Add 2 since there is the description line and
    " we want to start deleting after that item
    if line("$") > size
        exec 'silent! '.size.',$d'
    endif

    silent! write

    setlocal readonly

    " Test REMOVE
    " if a:auto_hide == 1
    "     silent! hide
    " endif

endfunction 

function! dbext#DB_commit()
    " Only valid for DBI and ODBC (perl)
    let driver = s:DB_get('type')
    if (driver !~ '\<DBI\>\|\<ODBC\>') 
        call s:DB_warningMsg(
                    \ "dbext:Commit and Rollback functionality only available ".
                    \ "when using the DBI or ODBC interfaces"
                    \ )
        return -1
    endif

    " Ensure the dbext_dbi plugin is loaded
    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    " If AutoCommit is on, there is no need to issue commits
    perl db_get_connection_option('AutoCommit')
    if g:dbext_dbi_result == -1
        call s:DB_runCmd("perl ".driver, "COMMIT", g:dbext_dbi_msg)
        return -1
    elseif g:dbext_dbi_result == 1
        call s:DB_warningMsg(
                    \ "dbext:Connection has autocommit set! "
                    \ )
        return -1
    endif

    perl db_commit()
    if g:dbext_dbi_result == -1
        call s:DB_runCmd("perl ".driver, "COMMIT", g:dbext_dbi_msg)
        return -1
    endif

    return 0
endfunction 

function! dbext#DB_rollback()
    " Only valid for DBI and ODBC (perl)
    let driver = s:DB_get('type')
    if (driver !~ '\<DBI\>\|\<ODBC\>') 
        call s:DB_warningMsg(
                    \ "dbext:Commit and Rollback functionality only available ".
                    \ "when using the DBI or ODBC interfaces"
                    \ )
        return -1
    endif

    " Ensure the dbext_dbi plugin is loaded
    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    " If AutoCommit is on, there is no need to issue commits
    perl db_get_connection_option('AutoCommit')
    if g:dbext_dbi_result == -1
        call s:DB_runCmd("perl ".driver, "ROLLBACK", g:dbext_dbi_msg)
        return -1
    elseif g:dbext_dbi_result == 1
        call s:DB_warningMsg(
                    \ "dbext:Connection has autocommit set! "
                    \ )
        return -1
    endif

    perl db_rollback()
    if g:dbext_dbi_result == -1
        call s:DB_runCmd("perl ".driver, "ROLLBACK", g:dbext_dbi_msg)
        return -1
    endif

    return 0
endfunction 

function! dbext#DB_connect()
    " Only valid for DBI and ODBC (perl)
    let type = s:DB_get('type')
    if (type !~ '\<DBI\>\|\<ODBC\>') 
        call s:DB_warningMsg(
                    \ "dbext:Connect and Disconnect functionality only available ".
                    \ "when using the DBI or ODBC interfaces"
                    \ )
        return -1
    endif

    if (type =~ '\<ODBC\>') 
        let driver       = 'ODBC'
        let conn_parms   = s:DB_get("dsnname")
    else
        let driver       = s:DB_get('driver')
        let conn_parms   = s:DB_get("conn_parms")
    endif
    " Ensure the dbext_dbi plugin is loaded
    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    let cmd = "perl db_is_connected()"
    exec cmd
    if g:dbext_dbi_result == -1
        call s:DB_runCmd("perl ".driver, cmd, g:dbext_dbi_msg)
        return -1
    endif

    " Each time we issue a connect, set the max rows, this
    " will ensure it is updated each time the user 
    " interacts with this layer.
    let g:dbext_dbi_max_rows = s:DB_get('DBI_max_rows')

    if g:dbext_dbi_result == 1
        " call s:DB_warningMsg("DB_Connected: already connected")
        return 0
    endif

    let user         = s:DB_get("user")
    let passwd       = s:DB_get("passwd")
    let driver_parms = s:DB_get("driver_parms")
    if (type =~ '\<ODBC\>') 
        let driver       = 'ODBC'
        let conn_parms   = s:DB_get("dsnname")
    else
        let driver       = s:DB_get('driver')
        let conn_parms   = s:DB_get("conn_parms")
    endif
    let cmd = "perl db_connect('".driver."', '".conn_parms."', '".user."', '".passwd."')"
    exec cmd
    if g:dbext_dbi_result == -1 
        call s:DB_runCmd("perl ".driver, cmd, g:dbext_dbi_msg)
        return -1
    endif
    if g:dbext_dbi_msg != ''
        call s:DB_runCmd("perl ".driver, cmd, g:dbext_dbi_msg)
    endif

    let parmlist = split(driver_parms, ';')

    " The driver parameters can be user defined.
    " They must be semi-colon separated in this format:
    "     AutoCommit=1;PrintError=0
	for parm in parmlist
        let var   = matchstr(parm, '^\w\+\ze\s*=.*')
        let value = matchstr(parm, '^\w\+\s*=\s*\zs.*')

        if var == ""
            call s:DB_warningMsg("Invalid driver parameters, format expected is:AutoCommit=1;LongReadLen=4096")
            return -1
        endif

        let cmd = "perl db_set_connection_option('".var."', '".value."')"
        exec cmd
        if g:dbext_dbi_result == -1
            call s:DB_runCmd("perl ".driver, cmd, g:dbext_dbi_msg)
            return -1
        endif
	endfor

    " If a login_script has been specified, execute it.
    " This must be done here for DBI or ODBC connections since the user
    " can Connect and Disconnect manually.  This is different from the
    " other types of databases which shell out and execute each command.
    " Check if a login_script has been specified
    let login_script = s:DB_getLoginScript(s:DB_get("login_script"))
    if login_script != ''
        let result = dbext#DB_execSql(login_script)
        if result == -1 
            return -1 
        endif
    endif

    return 0
endfunction 

function! dbext#DB_disconnect(...)
    let bufnr = bufnr("%")

    if a:0 > 0 && a:1 != ''
        let bufnr = matchstr(a:1, '\d\+')

        if bufnr == ''
            call s:DB_warningMsg(
                        \ "dbext: Input must be a buffer number "
                        \ )
            return -1
        endif
    endif

    " Only valid for DBI and ODBC (perl)
    let driver = s:DB_get('type')
    if (driver !~ '\<DBI\>\|\<ODBC\>') 
        call s:DB_warningMsg(
                    \ "dbext:Connect and Disconnect functionality only available ".
                    \ "when using the DBI or ODBC interfaces"
                    \ )
        return -1
    endif

    " Ensure the dbext_dbi plugin is loaded
    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    if bufnr == bufnr('%')
        " If AutoCommit is on, there is no need to issue commits
        " If AutoCommit is on disconnect, otherwise let the
        " user make the choice since it could intefere
        " with an already running transaction
        perl db_get_connection_option('AutoCommit')
        
        let is_AutoCommit = g:dbext_dbi_result 

        if is_AutoCommit == 0
            if s:DB_get('DBI_commit_on_disconnect') == 1 
                call dbext#DB_commit()
            else
                call dbext#DB_rollback()
            endif
        endif
    endif

    exec "perl db_disconnect( '".bufnr."' )"

    return 0
endfunction 

function! dbext#DB_disconnectAll()
    " Ensure the dbext_dbi plugin is loaded
    if s:DB_DBI_Autoload() == -1
        return -1
    endif

    perl db_disconnect_all()

    return 0
endfunction 

"}}}
call s:DB_buildLists()

call s:DB_resetGlobalParameters()

let &cpo = s:cpo_save
unlet s:cpo_save

" vim:fdm=marker:nowrap:ts=4:expandtab:ff=unix:
