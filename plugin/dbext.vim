" dbext.vim - Commn Database Utility
" ---------------------------------------------------------------
" Version:       4.20
" Maintainer:    David Fishburn <fishburn@ianywhere.com>
" Authors:       Peter Bagyinszki <petike1@dpg.hu>
"                David Fishburn <fishburn@ianywhere.com>
" Last Modified: Tue Dec 19 2006 10:39:10 PM
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

if exists('g:loaded_dbext') || &cp
    finish
endif
if v:version < 700
    echomsg "dbext: Version 4.00 or higher requires Vim7.  Version 3.50 can stil be used with Vim6."
    finish
endif
let g:loaded_dbext = 420

" Script variable defaults, these are used internal and are never displayed
" to the end user via the DBGetOption command  {{{
let s:dbext_buffers_with_dict_files = ''
let s:dbext_tempfile = fnamemodify(tempname(), ":h").
            \ (has('win32')?'\':'/').
            \ 'dbext.sql'
" }}}

" Build internal lists {{{
function! s:DB_buildLists()
    " Available DB types - maintainer in ()
    let s:db_types_mv = []
    "sybase adaptive server anywhere (fishburn)
    call add(s:db_types_mv, 'ASA')
    "sybase adaptive server enterprise (fishburn)
    call add(s:db_types_mv, 'ASE')
    "db2 (fishburn)
    call add(s:db_types_mv, 'DB2')
    "ingres (schoppet)
    call add(s:db_types_mv, 'INGRES')
    "interbase (bagyinszki)
    call add(s:db_types_mv, 'INTERBASE')
    "mysql (fishburn)
    call add(s:db_types_mv, 'MYSQL')
    "oracle (fishburn)
    call add(s:db_types_mv, 'ORA')
    "postgresql (fishburn)
    call add(s:db_types_mv, 'PGSQL')
    "microsoft sql server (fishburn)
    call add(s:db_types_mv, 'SQLSRV')
    "sqlite (fishburn)
    call add(s:db_types_mv, 'SQLITE')

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

    " Configuration parameters
    let s:config_params_mv = []
    call add(s:config_params_mv, 'use_sep_result_buffer')
    call add(s:config_params_mv, 'query_statements')
    call add(s:config_params_mv, 'parse_statements')
    call add(s:config_params_mv, 'prompt_for_parameters')
    call add(s:config_params_mv, 'prompting_user')
    call add(s:config_params_mv, 'always_prompt_for_variables')
    call add(s:config_params_mv, 'stop_prompt_for_variables')
    call add(s:config_params_mv, 'display_cmd_line')
    call add(s:config_params_mv, 'variable_def')
    call add(s:config_params_mv, 'buffer_defaulted')
    call add(s:config_params_mv, 'dict_show_owner')
    call add(s:config_params_mv, 'dict_table_file')
    call add(s:config_params_mv, 'dict_procedure_file')
    call add(s:config_params_mv, 'dict_view_file')
    call add(s:config_params_mv, 'replace_title')
    call add(s:config_params_mv, 'custom_title')
    call add(s:config_params_mv, 'use_tbl_alias')
    call add(s:config_params_mv, 'delete_temp_file')

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

    " DB server specific params
    " See below for 3 additional DB2 items
    let s:db_params_mv = []
    call add(s:db_params_mv, 'bin')
    call add(s:db_params_mv, 'cmd_header')
    call add(s:db_params_mv, 'cmd_terminator')
    call add(s:db_params_mv, 'cmd_options')
    call add(s:db_params_mv, 'on_error')

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
    let saveA = @a
    redir  @a
    silent! exec 'let'
    redir END
    let l:global_vars = @a
    let @a = saveA

    let prof_nm_re = 'dbext_default_profile_\zs\(\w\+\)'
    let index = match(l:global_vars, prof_nm_re)
    while index > -1
        " Retrieve the name of option
        let prof_name = matchstr(l:global_vars, '\w\+', index)
        if strlen(prof_name) > 0
            let prof_value = matchstr(l:global_vars, '\s*\zs[^'."\<C-J>".']\+', 
                        \ (index + strlen(prof_name))  )
            call add(s:conn_profiles_mv, prof_name)
        endif
        let index = index + strlen(prof_name)+ strlen(prof_value) + 1
        let index = match(l:global_vars, prof_nm_re, index)
    endwhile
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
function! s:DB_execFuncWCheck(name,...)
    " Record current buffer to return to the correct one
    let s:dbext_prev_winnr = winnr()
    let s:dbext_prev_bufnr = bufnr('%')
 
    let use_defaults = 1
    if s:DB_get("buffer_defaulted") != 1
        call s:DB_resetBufferParameters(use_defaults)
        if a:name == 'promptForParameters'
            " Handle the special case where no parameters were defaulted
            " but the process of resettting them has defaulted them.
            call s:DB_warningMsg( "dbext:Connection parameters have been defaulted" )
        elseif s:DB_get("buffer_defaulted") != 1
            call s:DB_warningMsg( "dbext:A valid database type must be chosen - a" )
            return -1
        endif
    endif

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
function! s:DB_execFuncTypeWCheck(name,...)

    " Record current buffer to return to the correct one
    let s:dbext_prev_winnr = winnr()
    let s:dbext_prev_bufnr = bufnr('%')
 
    let use_defaults = 1
    if s:DB_get("buffer_defaulted") != 1
        call s:DB_resetBufferParameters(use_defaults)
        if s:DB_get("buffer_defaulted") != 1
            call s:DB_warningMsg( "dbext:A valid database type must be chosen - b" )
            return -1
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
                    \ s:DB_option('T(', s:DB_get("type"),    ')  ') .
                    \ s:DB_option('H(', s:DB_get("host"),    ')  ') .
                    \ s:DB_option('P(', s:DB_get("port"),    ')  ') .
                    \ s:DB_option('S(', s:DB_get("srvname"), ')  ') .
                    \ s:DB_option('O(', s:DB_get("dsnname"), ')  ') .
                    \ s:DB_option('D(', s:DB_get("dbname"),  ')  ')

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

function! s:DB_setTitle() 
    let no_defaults = 0

    if s:DB_get("replace_title") == 1 && s:DB_get("type", no_defaults) != ''
        let &titlestring = s:DB_getTitle()
    endif

endfunction 

"" Set buffer parameter value
function! s:DB_set(name, value)
    if index(s:all_params_mv, a:name) > -1
        let value = a:value

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
            call s:DB_setTitle()
        endif
    else
        call s:DB_warningMsg("dbext:Unknown parameter: " . a:name)
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
function! DB_listOption(...)
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

    call s:DB_addToResultBuffer(option_list, "clear")

    return ""
endfunction

"" Get buffer parameter value
function! s:DB_get(name, ...)
    " Use defaults as the default for this function
    let use_defaults = ((a:0 > 0)?(a:1+0):1)
    let no_default   = 0

    let prefix = "b:dbext_"
    if index(s:script_params_mv, a:name) > -1
        let prefix = "s:dbext_"
    endif

    if exists(prefix.a:name)
        let retval = {prefix}{a:name} . '' "force string
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
function! s:DB_getWType(name)
    if exists("b:dbext_type")
        let retval = s:DB_get(b:dbext_type.'_'.a:name)
    else
        let retval = ""
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
    " ? - look for a question mark
    " w - MUST have word characters after it
    " W - CANNOT have any word characters after it
    " q - quotes do not matter
    " Q - CANNOT be surrounded in quotes
    " , - delimiter between options
    elseif a:name ==# "variable_def"            |return (exists("g:dbext_default_variable_def")?g:dbext_default_variable_def.'':'?WQ,@wq,:wq,$wq')
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
    elseif a:name ==# "use_win32_filenames"     |return (exists("g:dbext_default_use_win32_filenames")?g:dbext_default_use_win32_filenames.'':'0')
    elseif a:name ==# "dbext_version"           |return (g:loaded_dbext)
    elseif a:name ==# "history_file"            |return (exists("g:dbext_default_history_file")?g:dbext_default_history_file.'':(has('win32')?$VIM.'/dbext_sql_history.txt':$HOME.'/dbext_sql_history.txt'))
    elseif a:name ==# "history_bufname"         |return (fnamemodify(s:DB_get('history_file'), ":t:r"))
    elseif a:name ==# "history_size"            |return (exists("g:dbext_default_history_size")?g:dbext_default_history_size.'':'50')
    elseif a:name ==# "history_max_entry"       |return (exists("g:dbext_default_history_max_entry")?g:dbext_default_history_max_entry.'':'4096')
    elseif a:name ==# "ASA_bin"                 |return (exists("g:dbext_default_ASA_bin")?g:dbext_default_ASA_bin.'':'dbisql')
    elseif a:name ==# "ASA_cmd_terminator"      |return (exists("g:dbext_default_ASA_cmd_terminator")?g:dbext_default_ASA_cmd_terminator.'':';')
    elseif a:name ==# "ASA_cmd_options"         |return (exists("g:dbext_default_ASA_cmd_options")?g:dbext_default_ASA_cmd_options.'':'-nogui')
    elseif a:name ==# "ASA_on_error"            |return (exists("g:dbext_default_ASA_on_error")?g:dbext_default_ASA_on_error.'':'exit')
    elseif a:name ==# "ASE_bin"                 |return (exists("g:dbext_default_ASE_bin")?g:dbext_default_ASE_bin.'':'isql')
    elseif a:name ==# "ASE_cmd_terminator"      |return (exists("g:dbext_default_ASE_cmd_terminator")?g:dbext_default_ASE_cmd_terminator.'':"\ngo\n")
    elseif a:name ==# "ASE_cmd_options"         |return (exists("g:dbext_default_ASE_cmd_options")?g:dbext_default_ASE_cmd_options.'':'-w 10000')
    elseif a:name ==# "DB2_use_db2batch"        |return (exists("g:dbext_default_DB2_use_db2batch")?g:dbext_default_DB2_use_db2batch.'':(has('win32')?'0':'1'))
    elseif a:name ==# "DB2_bin"                 |return (exists("g:dbext_default_DB2_bin")?g:dbext_default_DB2_bin.'':'db2batch')
    elseif a:name ==# "DB2_cmd_options"         |return (exists("g:dbext_default_DB2_cmd_options")?g:dbext_default_DB2_cmd_options.'':'-q off -s off')
    elseif a:name ==# "DB2_db2cmd_bin"          |return (exists("g:dbext_default_DB2_db2cmd_bin")?g:dbext_default_DB2_db2cmd_bin.'':'db2cmd')
    elseif a:name ==# "DB2_db2cmd_cmd_options"  |return (exists("g:dbext_default_DB2_db2cmd_cmd_options")?g:dbext_default_DB2_db2cmd_cmd_options.'':'-c -w -i -t db2 -s')
    elseif a:name ==# "DB2_cmd_terminator"      |return (exists("g:dbext_default_DB2_cmd_terminator")?g:dbext_default_DB2_cmd_terminator.'':';')
    elseif a:name ==# "INGRES_bin"              |return (exists("g:dbext_default_INGRES_bin")?g:dbext_default_INGRES_bin.'':'sql')
    elseif a:name ==# "INGRES_cmd_terminator"   |return (exists("g:dbext_default_INGRES_cmd_terminator")?g:dbext_default_INGRES_cmd_terminator.'':'\p\g')
    elseif a:name ==# "INTERBASE_bin"           |return (exists("g:dbext_default_INTERBASE_bin")?g:dbext_default_INTERBASE_bin.'':'isql')
    elseif a:name ==# "INTERBASE_cmd_terminator"|return (exists("g:dbext_default_INTERBASE_cmd_terminator")?g:dbext_default_INTERBASE_cmd_terminator.'':';')
    elseif a:name ==# "MYSQL_bin"               |return (exists("g:dbext_default_MYSQL_bin")?g:dbext_default_MYSQL_bin.'':'mysql')
    elseif a:name ==# "MYSQL_cmd_terminator"    |return (exists("g:dbext_default_MYSQL_cmd_terminator")?g:dbext_default_MYSQL_cmd_terminator.'':';')
    elseif a:name ==# "MYSQL_version"           |return (exists("g:dbext_default_MYSQL_version")?g:dbext_default_MYSQL_version.'':'5')
    elseif a:name ==# "ORA_bin"                 |return (exists("g:dbext_default_ORA_bin")?g:dbext_default_ORA_bin.'':'sqlplus')
    elseif a:name ==# "ORA_cmd_header"          |return (exists("g:dbext_default_ORA_cmd_header")?g:dbext_default_ORA_cmd_header.'':"" .
                        \ "set pagesize 10000\n" .
                        \ "set wrap off\n" .
                        \ "set sqlprompt \"\"\n" .
                        \ "set flush off\n" .
                        \ "set colsep \"\t\"\n" .
                        \ "set tab off\n\n")
    elseif a:name ==# "ORA_cmd_options"         |return (exists("g:dbext_default_ORA_cmd_options")?g:dbext_default_ORA_cmd_options.'':"-S")
    elseif a:name ==# "ORA_cmd_terminator"      |return (exists("g:dbext_default_ORA_cmd_terminator")?g:dbext_default_ORA_cmd_terminator.'':";")
    elseif a:name ==# "PGSQL_bin"               |return (exists("g:dbext_default_PGSQL_bin")?g:dbext_default_PGSQL_bin.'':'psql')
    elseif a:name ==# "PGSQL_cmd_terminator"    |return (exists("g:dbext_default_PGSQL_cmd_terminator")?g:dbext_default_PGSQL_cmd_terminator.'':';')
    elseif a:name ==# "SQLITE_bin"              |return (exists("g:dbext_default_SQLITE_bin")?g:dbext_default_SQLITE_bin.'':'sqlite')
    elseif a:name ==# "SQLITE_cmd_header"       |return (exists("g:dbext_default_SQLITE_cmd_header")?g:dbext_default_SQLITE_cmd_header.'':".mode column\n.headers ON\n")
    elseif a:name ==# "SQLITE_cmd_terminator"   |return (exists("g:dbext_default_SQLITE_cmd_terminator")?g:dbext_default_SQLITE_cmd_terminator.'':';')
    elseif a:name ==# "SQLSRV_bin"              |return (exists("g:dbext_default_SQLSRV_bin")?g:dbext_default_SQLSRV_bin.'':'osql')
    elseif a:name ==# "SQLSRV_cmd_options"      |return (exists("g:dbext_default_SQLSRV_cmd_options")?g:dbext_default_SQLSRV_cmd_options.'':'-w 10000 -r -b -n')
    elseif a:name ==# "SQLSRV_cmd_terminator"   |return (exists("g:dbext_default_SQLSRV_cmd_terminator")?g:dbext_default_SQLSRV_cmd_terminator.'':"\ngo\n")
    elseif a:name ==# "prompt_profile"          |return (exists("g:dbext_default_prompt_profile")?g:dbext_default_prompt_profile.'':"" .
                \ (has('gui_running')?("[Optional] Enter profile #:\n".s:prompt_profile_list):
                \ (s:prompt_profile_list."\n[Optional] Enter profile #: "))
                \ )
    elseif a:name ==# "prompt_type"             |return (exists("g:dbext_default_prompt_type")?g:dbext_default_prompt_type.'':"" .
                \ (has('gui_running')?("\nPlease choose # of database type:".s:prompt_type_list):
                \ (s:prompt_type_list."\nPlease choose # of database type: "))
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
    " These are for name completion using Vim's dictionary feature
    elseif a:name ==# "dict_show_owner"         |return (exists("g:dbext_default_dict_show_owner")?g:dbext_default_dict_show_owner.'':'1')
    elseif a:name ==# "dict_table_file"         |return '' 
    elseif a:name ==# "dict_procedure_file"     |return '' 
    elseif a:name ==# "dict_view_file"          |return ''
    elseif a:name ==# "inputdialog_cancel_support"       |return (exists("g:dbext_default_inputdialog_cancel_support")?g:dbext_default_inputdialog_cancel_support.'':((v:version>=602)?'1':'0'))
    else                                        |return ''
    endif
                " \nPlease choose database type (from above ie ASA): ")
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

    " Reset configuration parameters to defaults
    for param in s:config_params_mv
        call s:DB_set(param, s:DB_get(param))
    endfor

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
                call s:DB_set(param, s:DB_get(param))
            endif
        endif
    endfor

    " If a database type has been chosen, do not prompt
    " for connection information
    if s:DB_get("type", no_defaults) == "" && a:use_defaults == 1
        call s:DB_promptForParameters()
    endif

    call s:DB_validateBufferParameters()

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

    call s:DB_set('prompting_user', 1)
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
                if l:new_value > 0 && l:new_value <= 
                            \ len(s:conn_profiles_mv)
                    let retval = s:conn_profiles_mv[(l:new_value-1)]
                    call s:DB_set(param, retval)
                else
                    call s:DB_set(param, "")
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
    call s:DB_set('prompting_user', 0)

    return retval
endfunction

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
            call s:DB_resetBufferParameters(no_defaults)

            let rc = s:DB_setMultipleOptions(mdl_options)
            if rc > -1
                call s:DB_validateBufferParameters()
            endif
            break
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
    let stripped = substitute(a:str, '[ \t\r\n]\+', '\n', 'g')
    " This has the side effect of adding a blank line at the top
    let stripped = substitute(stripped, '^[\r\n]\+', '', '')
    " Now take care of the other end of the string
    let stripped = substitute(stripped, '\([ \t]\+\)\([\r\n]\+\)', '\2', 'g')

    return stripped
endfunction

function! s:DB_stripComments(mdl_options)
    let rc = 0
    let comment_chars = ""
    if &comments != ""
        " Based on filetypes, determine what all the comment characters are
        let comment_chars = &comments
        " Escape any special characters
        let comment_chars = substitute(comment_chars, '[*/$]', '\\&', 'g' )
        " Convert the beginning option to a \|
        let comment_chars = substitute(comment_chars, '^.\{-}:', '\\|', '' )
        " Convert remaining options a separators \|
        let comment_chars = substitute(comment_chars, ',.\{-}:', '\\|', 'g')
    endif

    " Put these together so that the dbext: modeline will automatically
    " strip spaces and comments characters from the end of it.
    let strip_end_expr = ':\?\s*\(,'.comment_chars.'\)\?\s*$'

    return substitute(a:mdl_options, strip_end_expr, '', '')
endfunction

function! s:DB_setMultipleOptions(multi_options)
    let rc = 0

    " Strip leading or following quotes, single or double
    let options_cs = s:DB_stripLeadFollowQuotesSpace(a:multi_options)

    " Choose a bad separator (:), and it is too late to choose another one
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

    " Convert the comma  separate list into a List
    let options_mv = split(options_cs, ':')
    " Loop through and prompt the user for all buffer connection parameters.
    for option in options_mv
        if strlen(option) > 0
            " Retrieve the option name 
            let opt_name  = matchstr(option, '.\{-}\ze=')
            let opt_value = matchstr(option, '=\zs.*')
            let opt_value = s:DB_stripLeadFollowQuotesSpace(opt_value)

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

" Commands {{{
command! -nargs=+ DBExecSQL      :call s:DB_execSql(<q-args>)
command! -range -nargs=0 DBExecRangeSQL <line1>,<line2>call s:DB_execRangeSql()
command! -nargs=+ Call           :call s:DB_execSql("call " . <q-args>)
command! -nargs=+ Select         :call s:DB_execSql("select " . <q-args>)
command! -nargs=+ Update         :call s:DB_execSql("update " . <q-args>)
command! -nargs=+ Insert         :call s:DB_execSql("insert " . <q-args>)
command! -nargs=+ Delete         :call s:DB_execSql("delete " . <q-args>)
command! -nargs=+ Drop           :call s:DB_execSql("drop " . <q-args>)
command! -nargs=+ Alter          :call s:DB_execSql("alter " . <q-args>)
command! -nargs=+ Create         :call s:DB_execSql("create " . <q-args>)
command! -nargs=1 DBSetOption    :call s:DB_setMultipleOptions(<q-args>)
command! -nargs=? DBGetOption    :echo DB_listOption(<q-args>)
command! -nargs=* -complete=customlist,<SID>DB_settingsComplete DBSetOption :call s:DB_setMultipleOptions(<q-args>)
command! -nargs=* -complete=customlist,<SID>DB_settingsComplete DBGetOption :echo DB_listOption(<q-args>)

if !exists(':DBExecVisualSQL')
    command! -nargs=0 -range DBExecVisualSQL :call s:DB_execSql(DB_getVisualBlock())
    vmap <unique> <script> <Plug>DBExecVisualSQL :DBExecVisualSQL<CR>
endif
if !exists(':DBExecSQLUnderCursor')
    command! -nargs=0 DBExecSQLUnderCursor
                \ :call s:DB_execSql(s:DB_getQueryUnderCursor())
    nmap <unique> <script> <Plug>DBExecSQLUnderCursor :DBExecSQLUnderCursor<CR>
endif
if !exists(':DBExecSQL')
    command! -nargs=0 DBExecSQL
                \ :call s:DB_execSql(s:DB_parseQuery(s:DB_getQueryUnderCursor()))
    nmap <unique> <script> <Plug>DBExecSQL :DBExecSQL<CR>
endif
if !exists(':DBSelectFromTable')
    command! -nargs=* -range DBSelectFromTable
                \ :call s:DB_execSqlWithDefault("select * from ", <f-args>)
    nmap <unique> <script> <Plug>DBSelectFromTable :DBSelectFromTable<CR>
endif
if !exists(':DBSelectFromTableWithWhere')
    command! -nargs=0 DBSelectFromTableWithWhere
                \ :call s:DB_execSql("select * from " .
                \ expand("<cword>") . " where " .
                \ input("Please enter where clause: "))
    nmap <unique> <script> <Plug>DBSelectFromTableWithWhere
                \ :DBSelectFromTableWithWhere<CR>
endif
if !exists(':DBSelectFromTableAskName')
    command! -nargs=0 DBSelectFromTableAskName
                \ :call s:DB_selectTablePrompt()
    nmap <unique> <script> <Plug>DBSelectFromTableAskName
                \ :DBSelectFromTableAskName<CR>
endif
if !exists(':DBDescribeTable')
    command! -nargs=* -range DBDescribeTable
                \ :call s:DB_describeTable(<f-args>)
    nmap <unique> <script> <Plug>DBDescribeTable :DBDescribeTable<CR>
endif
if !exists(':DBDescribeTableAskName')
    command! -nargs=0 DBDescribeTableAskName
                \ :call s:DB_describeTablePrompt()
    nmap <unique> <script> <Plug>DBDescribeTableAskName
                \ :DBDescribeTableAskName<CR>
endif
if !exists(':DBDescribeProcedure')
    command! -nargs=* -range DBDescribeProcedure
                \ :call s:DB_describeProcedure(<f-args>)
    nmap <unique> <script> <Plug>DBDescribeProcedure :DBDescribeProcedure<CR>
endif
if !exists(':DBDescribeProcedureAskName')
    command! -nargs=0 DBDescribeProcedureAskName
                \ :call s:DB_describeProcedurePrompt()
    nmap <unique> <script> <Plug>DBDescribeProcedureAskName
                \ :DBDescribeProcedureAskName<CR>
endif
if !exists(':DBPromptForBufferParameters')
    command! -nargs=0 DBPromptForBufferParameters
                \ :call s:DB_execFuncWCheck('promptForParameters')
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
                \ :call s:DB_getListTable(<f-args>)
    nmap <unique> <script> <Plug>DBListTable
                \ :DBListTable<CR>
endif
if !exists(':DBListProcedure')
    command! -nargs=? DBListProcedure
                \ :call s:DB_getListProcedure(<f-args>)
    nmap <unique> <script> <Plug>DBListProcedure
                \ :DBListProcedure<CR>
endif
if !exists(':DBListView')
    command! -nargs=? DBListView
                \ :call s:DB_getListView(<f-args>)
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
                \ :call s:DB_checkModeline()
end
if !exists(':DBRefreshResult')
    command! -nargs=0 DBRefreshResult
                \ :call s:DB_runPrevCmd(s:dbext_prev_sql)
end
if !exists(':DBHistory')
    command! -nargs=0 DBHistory
                \ :call s:DB_historyList()
    nmap <unique> <script> <Plug>DBHistory :DBHistory<CR>
end
if !exists(':DBCloseResults')
    command! -nargs=0 DBCloseResults
                \ :call s:DB_closeWindow('%')
end
"}}}
" Mappings {{{
if !hasmapto('<Plug>DBExecVisualSQL')
    vmap <unique> <Leader>se <Plug>DBExecVisualSQL
endif
if !hasmapto('<Plug>DBExecSQLUnderCursor')
    nmap <unique> <Leader>se <Plug>DBExecSQLUnderCursor
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
"}}}
" Menus {{{
if has("gui_running") && has("menu")
    vnoremenu <script> Plugin.dbext.Execute\ SQL\ (Visual\ selection) :DBExecVisualSQL<CR>
    noremenu <script> Plugin.dbext.Execute\ SQL\ (Under\ cursor) :DBExecSQLUnderCursor<CR>
    " noremenu <script> Plugin.dbext.Execute\ SQL :DBExecSQLUnderCursor<CR>
    noremenu <script> Plugin.dbext.Select\ Table
                \ :DBSelectFromTable<CR>
    inoremenu <script> Plugin.dbext.Select\ Table
                \ <C-O>:DBSelectFromTable<CR>
    vnoremenu <script> Plugin.dbext.Select\ Table
                \ :<C-U>exec "DBSelectFromTable ".DB_getVisualBlock()<CR>
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
endif
"}}}
" ASA exec {{{
function! s:DB_ASA_execSql(str)
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let output = s:DB_getWType("cmd_header") . a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(s:DB_getWType("cmd_terminator")) . 
                \ '['."\n".' \t]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))

    if s:DB_get("host") != "" || s:DB_get("port") != ""
        let links = 'tcpip(' .
                \ s:DB_option('host=', s:DB_get("host"), ';') .
                \ s:DB_option('port=', s:DB_get("port"), '') .
                \ ')'
    else
        let links = ""
    endif
    let cmd = dbext_bin .  ' ' . s:DB_getWType("cmd_options") . ' ' .
                \ s:DB_option('-onerror ', s:DB_getWType("on_error"), ' ') .
                \ ' -c "' .
                \ s:DB_option('uid=', s:DB_get("user"), ';') .
                \ s:DB_option('pwd=', s:DB_get("passwd"), ';') .
                \ s:DB_option('dsn=', s:DB_get("dsnname"), ';') .
                \ s:DB_option('eng=', s:DB_get("srvname"), ';') .
                \ s:DB_option('dbn=', s:DB_get("dbname"), ';') .
                \ s:DB_option('links=', links, ';') .
                \ s:DB_option('', s:DB_get("extra"), '') 
    if has("win32") && s:DB_get("integratedlogin") == 1
        let cmd = cmd . 
                \ s:DB_option('int=', 'yes', ';') 
    endif
    let cmd = cmd .  '" ' . 
                \ ' read ' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output)

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
    " Strip off query statistics
    let stripped = substitute( stripped, '(First \d\+ rows\_.*', '', '' )
    " Strip off trailing spaces
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
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
" ASE exec {{{
function! s:DB_ASE_execSql(str)
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let output = s:DB_getWType("cmd_header") . a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(s:DB_getWType("cmd_terminator")) . 
                \ '['."\n".' \t]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))

    let cmd = dbext_bin . ' ' .
                \ s:DB_option('',    s:DB_getWType("cmd_options"), ' ') .
                \ s:DB_option('-U ', s:DB_get("user"), ' ') .
                \ s:DB_option('-P ', s:DB_get("passwd"), ' ') .
                \ s:DB_option('-H ', s:DB_get("host"), ' ') .
                \ s:DB_option('-S ', s:DB_get("srvname"), ' ') .
                \ s:DB_option('-D ', s:DB_get("dbname"), ' ') .
                \ s:DB_option('', s:DB_get("extra"), '') .
                \ ' -i ' . s:dbext_tempfile

    let result = s:DB_runCmd(cmd, output)

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
    " Strip off query statistics
    let stripped = substitute( stripped, '(\d\+ rows\_.*', '', '' )
    " Strip off trailing spaces
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
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


    if s:DB_getWType("use_db2batch") == '1'
        " All defaults are specified in the DB_getDefault function.
        " This contains the defaults settings for all database types
        let output = s:DB_getWType("cmd_header") . a:str
        " Only include a command terminator if one has not already
        " been added
        if output !~ s:DB_escapeStr(s:DB_getWType("cmd_terminator")) . 
                    \ '['."\n".' \t]*$'
            let output = output . s:DB_getWType("cmd_terminator")
        endif

        exe 'redir! > ' . s:dbext_tempfile
        silent echo output
        redir END

        let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))

        let cmd = dbext_bin .  ' ' . s:DB_getWType("cmd_options")
        if s:DB_get("user") != ""
            let cmd = cmd . ' -a ' . s:DB_get("user") . '/' .
                        \ s:DB_get("passwd") . ' '
        endif
        let cmd = cmd . 
                    \ s:DB_option(' ', s:DB_get("extra"), ' ') .
                    \ s:DB_option('-d ', s:DB_get("dbname"), ' ') .
                    \ s:DB_option('-l ', s:DB_getWType("cmd_terminator"), ' ').
                    \ ' -f ' . s:dbext_tempfile

    else
        " Use db2cmd instead

        let connect_str = 'CONNECT ' .
                    \ s:DB_option('TO ', s:DB_get("dbname"), ' ') .
                    \ s:DB_option('USER ', s:DB_get("user"), ' ') .
                    \ s:DB_option('USING ', s:DB_get("passwd"), '') .
                    \ s:DB_option('', s:DB_getWType("cmd_terminator"), '') .
                    \ "\n"

        " All defaults are specified in the DB_getDefault function.
        " This contains the defaults settings for all database types
        let output = s:DB_getWType("db2cmd_cmd_header") . connect_str . a:str
        " Only include a command terminator if one has not already
        " been added
        if output !~ s:DB_escapeStr(s:DB_getWType("cmd_terminator")) . 
                    \ '['."\n".' \t]*$'
            let output = output . s:DB_getWType("cmd_terminator")
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

        let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("db2cmd_bin"))

        let cmd = dbext_bin .  ' ' . s:DB_getWType("db2cmd_cmd_options")
        let cmd = cmd . ' ' .  s:DB_option('', s:DB_get("extra"), ' ') .
                    \ s:DB_option('-t', s:DB_getWType("cmd_terminator"), ' ') .
                    \ '-f ' . s:dbext_tempfile
    endif


    let result = s:DB_runCmd(cmd, output)

    return result
endfunction

function! s:DB_DB2_describeTable(table_name)
    let save_use_db2batch = s:DB_getWType("use_db2batch")
    call s:DB_setWType("use_db2batch", 0)

    call s:DB_DB2_execSql(
                \ "DESCRIBE TABLE ".a:table_name." SHOW DETAIL".
                \ s:DB_getWType("cmd_terminator") .
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
    if s:DB_getWType("use_db2batch") == '1'
        " Strip off column headers ending with a newline
        let stripped = substitute( a:result, '\_.*-\s*'."[\<C-J>]", '', '' )
        " Strip off trailing spaces
        let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
        " Strip off query statistics
        let stripped = substitute( stripped, 'Number of rows\_.*', '', '' )
    else
        " Strip off column headers ending with a newline
        let stripped = substitute( a:result, '\_.*-\s*', '', '' )
        " Strip off query statistics
        let stripped = substitute( stripped, "\n".'\s*\d\+\s\+record(s)\s\+selected\_.*', '', '' )
        " Strip off trailing spaces
        let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
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
    let output = s:DB_getWType("cmd_header") . a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(s:DB_getWType("cmd_terminator")) . 
                \ '['."\n".' \t]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . 
                \ s:DB_option('', s:DB_get("extra"), ' ') .
                \ s:DB_option('-S ', s:DB_get("dbname"), ' ') .
                \ s:DB_option('', s:DB_getWType("cmd_options"), ' ') .
                \ ' < ' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output)

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
    let output = s:DB_getWType("cmd_header") . a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(s:DB_getWType("cmd_terminator")) . 
                \ '['."\n".' \t]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . 
                \ s:DB_option('-username ', s:DB_get("user"), ' ') .
                \ s:DB_option('-password ', s:DB_get("passwd"), ' ') .
                \ s:DB_option('', s:DB_getWType("cmd_options"), ' ') .
                \ s:DB_option('', s:DB_getWType("extra"), ' ') .
                \ '-input ' . s:dbext_tempfile .
                \ s:DB_option(' ', s:DB_get("dbname"), '')
    let result = s:DB_runCmd(cmd, output)

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
    let output = s:DB_getWType("cmd_header") . a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(s:DB_getWType("cmd_terminator")) . 
                \ '['."\n".' \t]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . s:DB_getWType("cmd_options")
    let cmd = cmd .
                \ s:DB_option(' -u ', s:DB_get("user"), '') .
                \ s:DB_option(' -p',  s:DB_get("passwd"), '') .
                \ s:DB_option(' -h ', s:DB_get("host"), '') .
                \ s:DB_option(' -P ', s:DB_get("port"), '') .
                \ s:DB_option(' -D ', s:DB_get("dbname"), '') .
                \ s:DB_option(' ', s:DB_get("extra"), '') .
                \ ' < ' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output)

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
    if s:DB_getWType('version') < '5'
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
    if s:DB_getWType('version') < '5'
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
    " Strip off header separators ending with a newline
    let stripped = substitute( stripped, '+[-]\|.\{-}'."[\<C-V>\<C-J>]", '', '' )
    " Strip off column headers ending with a newline
    let stripped = substitute( stripped, '|.*Tables_in.*'."[\<C-V>\<C-J>]", '', '' )
    " Strip off preceeding and ending |s
    let stripped = substitute( stripped, '|', '', 'g' )
    " Strip off trailing spaces
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
    return stripped
endfunction "}}}

function! s:DB_MYSQL_getDictionaryTable() "{{{
    if s:DB_getWType('version') < '5'
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
    if s:DB_getWType('version') < '5'
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
    if s:DB_getWType('version') < '5'
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
        call s:DB_errorMsg("dbext:You must specify a database name/file")
        return -1
    endif

    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let output = s:DB_getWType("cmd_header") . a:str
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
                \ last_line !~ s:DB_getWType("cmd_terminator") . '['."\n".' \t]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . s:DB_getWType("cmd_options")
    let cmd = cmd .
                \ s:DB_option(' ', s:DB_get("extra"), '') .
                \ s:DB_option(' ', s:DB_get("dbname"), '') .
                \ ' < ' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output)

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
    " let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
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
    let output = s:DB_getWType("cmd_header") . a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(s:DB_getWType("cmd_terminator")) . 
                \ '['."\n".' \t]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif
    " Added quit to the end of the command to exit SQLPLUS
    if output !~ s:DB_escapeStr("\nquit".s:DB_getWType("cmd_terminator")) . 
                \ '['."\n".' \t]*$'
        let output = output . "\nquit".s:DB_getWType("cmd_terminator")
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))

    let cmd = dbext_bin .  
                \ ' ' . s:DB_getWType("cmd_options") .
                \ s:DB_option(' ', s:DB_get("user"), '') .
                \ s:DB_option('/', s:DB_get("passwd"), '') .
                \ s:DB_option('@', s:DB_get("srvname"), '') .
                \ s:DB_option(' ', s:DB_get("extra"), '') .
                \ ' @' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output)

    return result
endfunction

function! s:DB_ORA_describeTable(table_name)
    return s:DB_ORA_execSql("desc " . a:table_name)
endfunction

function! s:DB_ORA_describeProcedure(procedure_name)
    return s:DB_ORA_execSql("desc " . a:procedure_name)
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
    let query =   "select object_name, owner ".
                \ "  from all_objects ".
                \ " where object_type IN ('PROCEDURE', 'PACKAGE', 'FUNCTION') ".
                \ "   and object_name LIKE '".obj_name."%' "
    if strlen(owner) > 0
        let query = query .
                    \ "   and owner = '".owner."' "
    endif
    let query = query .
                \ " order by object_name"
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
    let query = query .
                \ " order by view_name"
    return s:DB_ORA_execSql( query )
endfunction 

function! s:DB_ORA_getListColumn(table_name) "{{{
    let owner      = toupper(s:DB_getObjectOwner(a:table_name))
    let table_name = toupper(s:DB_getObjectName(a:table_name))
    let query =   "select column_name     ".
                \ "  from ALL_TAB_COLUMNS ".
                \ " where table_name = '".table_name."' "
    if strlen(owner) > 0
        let query = query .
                    \ "   and owner = '".owner."' "
    endif
    let query = query .
                \ " order by column_id"
    let result = s:DB_ORA_execSql( query )
    return s:DB_ORA_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_ORA_stripHeaderFooter(result) "{{{
    " Strip off column headers ending with a newline
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-J>]", '', '' )
    " Strip off query statistics
    let stripped = substitute( stripped, '\d\+ rows\_.*', '', '' )
    " Strip off no rows selected
    let stripped = substitute( stripped, 'no rows selected\_.*', '', '' )
    " Strip off trailing spaces
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
    return stripped
endfunction "}}}

function! s:DB_ORA_getDictionaryTable() "{{{
    let result = s:DB_ORA_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"owner||'.'||":'')."table_name" .
                \ "  from ALL_ALL_TABLES " .
                \ " order by ".(s:DB_get('dict_show_owner')==1?"owner, ":'')."table_name  "
                \ )
    return s:DB_ORA_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_ORA_getDictionaryProcedure() "{{{
    let result = s:DB_ORA_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"owner||'.'||":'')."object_name                          " .
                \ "  from all_objects                          " .
                \ " where object_type IN                       " .
                \ "       ('PROCEDURE', 'PACKAGE', 'FUNCTION') " .
                \ " order by ".(s:DB_get('dict_show_owner')==1?"owner, ":'')."object_name                       "
                \ )
    return s:DB_ORA_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_ORA_getDictionaryView() "{{{
    let result = s:DB_ORA_execSql(
                \ "select ".(s:DB_get('dict_show_owner')==1?"owner||'.'||":'')."view_name    " .
                \ "  from ALL_VIEWS    " .
                \ " order by ".(s:DB_get('dict_show_owner')==1?"owner, ":'')."view_name "
                \ )
    return s:DB_ORA_stripHeaderFooter(result)
endfunction "}}}
"}}}
" PGSQL exec {{{
function! s:DB_PGSQL_execSql(str)
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let output = s:DB_getWType("cmd_header") . a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(s:DB_getWType("cmd_terminator")) . 
                \ '['."\n".' \t]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . 
                \ s:DB_option('', s:DB_getWType("cmd_options"), ' ') .
                \ s:DB_option('-d ', s:DB_get("dbname"), ' ') .
                \ s:DB_option('-U ', s:DB_get("user"), ' ') .
                \ s:DB_option('-h ', s:DB_get("host"), ' ') .
                \ s:DB_option('-p ', s:DB_get("port"), ' ') .
                \ s:DB_option(' ', s:DB_get("extra"), '') .
                \ ' -q -f ' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output)

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
    " Strip off query statistics
    let stripped = substitute( stripped, '(\d\+ rows\_.*', '', '' )
    " Strip off trailing spaces
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
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
" SQLSRV exec {{{
function! s:DB_SQLSRV_execSql(str)
    let output = s:DB_getWType("cmd_header") . a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_escapeStr(s:DB_getWType("cmd_terminator")) . 
                \ '['."\n".' \t]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    exe 'redir! > ' . s:dbext_tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))

    let cmd = dbext_bin . ' ' . s:DB_getWType("cmd_options")

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
                \ s:DB_option(' ', s:DB_get("extra"), '') .
                \ ' -i ' . s:dbext_tempfile
    let result = s:DB_runCmd(cmd, output)

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
    " Strip off query statistics
    let stripped = substitute( stripped, '(\d\+ rows\_.*', '', '' )
    " Strip off trailing spaces
    let stripped = substitute( stripped, '\(\<\w\+\>\)\s*', '\1', 'g' )
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
" Selector functions {{{
function! s:DB_execSql(query)
    let query = a:query

    if strlen(query) == 0
        call s:DB_warningMsg("dbext:No statement to execute!")
        return
    endif

   " Add query to internal history
    call s:DB_historyAdd(query)
    
    if s:DB_get("prompt_for_parameters") == "1"
        let query = s:DB_parseQuery(query)
    endif
    
    if query != ""
        return s:DB_execFuncTypeWCheck('execSql', query)
    endif
endfunction

function! s:DB_execSqlWithDefault(...)
    if (a:0 > 0)
        let sql = a:1
    else
        call s:DB_warningMsg("dbext:No statement to execute!")
        return
    endif
    if(a:0 > 1)
        let sql = sql . a:2
    else
        let sql = sql . expand("<cword>")
    endif
    
    return s:DB_execSql(sql)
endfunction

function! s:DB_execRangeSql() range
    if a:firstline != a:lastline
        let saveR = @"
        silent! exec a:firstline.','.a:lastline.'y'
        let query = @"
        let @" = saveR
    else
        let query = getline(a:firstline)
    endif

    return s:DB_execSql(query)
endfunction

function! s:DB_describeTable(...)
    if(a:0 > 0)
        let table_name = substitute(a:1, '\s*\(\S\+\).*', '\1', '')
    else
        let table_name = expand("<cword>")
    endif
    return s:DB_execFuncTypeWCheck('describeTable', table_name)
endfunction

function! s:DB_describeProcedure(...)
    if(a:0 > 0)
        let procedure_name = substitute(a:1, '\s*\(\S\+\).*', '\1', '')
    else
        let procedure_name = expand("<cword>")
    endif
    return s:DB_execFuncTypeWCheck('describeProcedure', procedure_name)
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

    " Remove any newline characters (especially from Visual mode)
    let table_name = substitute( table_name, "[\<C-J>]*", '', 'g' )
    if table_name == ""
        call s:DB_warningMsg( 'dbext:You must supply a table name' )
        return
    endif

    " This will return the result instead of using the result buffer
    let l:prev_use_result_buffer = s:DB_get('use_result_buffer')
    call s:DB_set('use_result_buffer', 0)
    let col_list = s:DB_execFuncTypeWCheck('getListColumn', table_name)
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
        let col_list = substitute( col_list, '\<\w\+\>', tbl_alias.'&', 'g' )
    endif
    
    if use_newline_sep == 0
        " Convert newlines into commas
        " let col_list = substitute( col_list, '\w\>\zs[ '."\<C-J>".']*\ze\w', '\1, ', 'g' )
        let col_list = substitute( col_list, '\w\>\zs[^.].\{-}\ze\<\w', ', ', 'g' )
        " Make sure the column list does not end in a newline, makes
        " pasting into a buffer more difficult since  you cannot 
        " insert it between words
        let col_list = substitute( col_list, "\\s*\\n$", '', '' )
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

function! s:DB_getListTable(...)
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
    return s:DB_execFuncTypeWCheck('getListTable', table_prefix)
endfunction

function! s:DB_getListProcedure(...)
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
    return s:DB_execFuncTypeWCheck('getListProcedure', proc_prefix)
endfunction

function! s:DB_getListView(...)
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
    return s:DB_execFuncTypeWCheck('getListView', view_prefix)
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

function! s:DB_getQueryUnderCursor()
    let use_defaults = 1
    " In order to parse a statement, we must know what database type
    " we are dealing with to choose the correct cmd_terminator
    if s:DB_get("buffer_defaulted") != 1
        call s:DB_resetBufferParameters(use_defaults)
        if s:DB_get("buffer_defaulted") != 1
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
    let dbext_cmd_terminator = s:DB_getWType('cmd_terminator')
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
    let sql_commands = '\c^\s*\<\('.dbext_query_statements.'\)\>'

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
        exe 'silent! norm! v/'.dbext_cmd_terminator."\\s*$/e\n".'"zy``'
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

function! s:DB_selectTablePrompt()
    return s:DB_execSql("select * from " .
                    \input("Please enter the name of the table to select from: "))
endfunction

function! s:DB_describeTablePrompt()
    return s:DB_describeTable(
                    \input("Please enter the name of the table to describe: "))
endfunction

function! s:DB_describeProcedurePrompt()
    return s:DB_describeProcedure(input("Please enter the name of the procedure to describe: "))
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

function! DB_getVisualBlock() range
    let save = @"
    silent normal gvy
    let vis_cmd = @"
    let @" = save
    return vis_cmd
endfunction 

function! s:DB_settingsComplete(ArgLead, CmdLine, CursorPos)
    let items = copy(s:all_params_mv)
    if a:ArgLead != ''
        let items = filter(items, "v:val =~ '^".a:ArgLead."'")
    endif
    return items
endfunction
function! s:DB_getObjectOwner(object) "{{{
    " The owner regex matches a word at the start of the string which is
    " followed by a dot, but doesn't include the dot in the result.
    " ^    - from beginning of line
    " "\?  - ignore any quotes
    " \zs  - start the match now
    " \w\+ - get owner name
    " \ze  - end the match
    " "\?  - ignore any quotes
    " \.   - must by followed by a .
    let owner = matchstr( a:object, '^"\?\zs\w\+\ze"\?\.' )
    return owner
endfunction "}}}
function! s:DB_getObjectName(object) "{{{
    " The object regex matches a word at the start of the string, skipping over
    " any owner name if there is one.  Only the object name is returned.
    " ^    - from beginning of line
    " \(   - start of optional owner name
    "        "\?  - ignore any quotes
    "        \w*  - get owner name
    "        "\?  - ignore any quotes
    "        \.   - must be followed by a .
    " \)\? - entire match is optional
    " "\?  - ignore any quotes
    " \zs  - start match
    " \w\+ - get procedure name 
    let object  = matchstr( a:object, '^\("\?\w*"\?\.\)\?"\?\zs\w*' )
    return object
endfunction "}}}

"" Get buffer parameter value
function! DB_execCmd(name, ...)

    let l:prev_use_result_buffer = s:DB_get('use_result_buffer')
    call s:DB_set('use_result_buffer', 0)
    " Could not figure out how to do this with an unlimited #
    " of variables, so I limited this to 4.  Currently we only use
    " 1 parameter in the code (May 2004), so that should be fine.
    " return s:DB_execFuncTypeWCheck('describeTable', table_name)
    if a:0 == 0
        let result = s:DB_execFuncWCheck(a:name)
    elseif a:0 == 1
        let result = s:DB_execFuncWCheck(a:name, a:1)
    elseif a:0 == 2
        let result = s:DB_execFuncWCheck(a:name, a:1, a:2)
    elseif a:0 == 3
        let result = s:DB_execFuncWCheck(a:name, a:1, a:2, a:3)
    else
        let result = s:DB_execFuncWCheck(a:name, a:1, a:2, a:3, a:4)
    endif
    call s:DB_set('use_result_buffer', l:prev_use_result_buffer)
    
    return result
endfunction
"}}}
" Dictionary (Completion) Functions {{{
function! s:DB_addBufDictList( buf_nbr ) "{{{
    if s:dbext_buffers_with_dict_files !~ '\<'.a:buf_nbr.','
        let s:dbext_buffers_with_dict_files = 
                    \ s:dbext_buffers_with_dict_files . a:buf_nbr . ','
    endif
endfunction "}}}
function! s:DB_delBufDictList( buf_nbr ) "{{{
    " If the buffer has temporary files
    if s:dbext_buffers_with_dict_files =~ '\<'.a:buf_nbr.','
        " If all temporary files have been deleted
        if s:DB_get('dict_table_file') == '' && 
                    \ s:DB_get('dict_procedure_file') == '' && 
                    \ s:DB_get('dict_view_file') == ''
            " Remove the buffer number from the list
            let s:dbext_buffers_with_dict_files = 
                        \ substitute( s:dbext_buffers_with_dict_files,
                        \ '\<' . a:buf_nbr . ',', 
                        \ '',
                        \ '' )
        endif
    endif
endfunction "}}}
function! DB_DictionaryCreate( drop_dict, which ) "{{{
    " Store the lower case name, sometimes we use the 
    " a:which variable which has an Upper Case first letter,
    " but for variables names we use the lower case which_dict
    let which_dict = tolower(a:which)
    
    " First check if we are refreshing the table dictionary
    " If so, remove it 
    call s:DB_DictionaryDelete( which_dict )

    " Give the user the ability to remove a dictionary
    if a:drop_dict == 1
        return ""
    endif

    let l:prev_use_result_buffer = s:DB_get('use_result_buffer')
    call s:DB_set('use_result_buffer', 0)
    " let dict_list = s:DB_{b:dbext_type}_getDictionary{a:which}()
    let dict_list = s:DB_execFuncTypeWCheck('getDictionary'.a:which)
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

        return temp_file
    else
        call s:DB_warningMsg( 'dbext:Failed to create ' . which_dict . ' dictionary' )
    endif

    return -1 
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
function! DB_getDictionaryName( which ) "{{{
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
function! s:DB_auVimLeavePre() "{{{
    if s:DB_get("delete_temp_file") == 1
        let rc = delete(s:dbext_tempfile)
    endif

    " This function will loop through all open buffers that use dbext
    " and have created temporary dictionary files.

    " Return if no files have a dictionary
    if strlen(s:dbext_buffers_with_dict_files) == 0
        return
    endif

    " Save the current buffer to switch back to
    let cur_buf = bufnr("%")

    " Find the first buffer number with temporary dictionary files created
    let buf_nbr = matchstr( s:dbext_buffers_with_dict_files, '\<\d\+' )

    " For each buffer, cleanup the temporary dictionary files
    while strlen(buf_nbr) > 0
        " Switch to the buffer being deleted
        silent! exec buf_nbr.'buffer'

        call s:DB_DictionaryDelete( 'Table' )
        call s:DB_DictionaryDelete( 'Procedure' )
        call s:DB_DictionaryDelete( 'View' )

        " DB_DictionaryDelete will remove the buffer number from 
        " dbext_buffers_with_temp_files, so just match on the first #
        let buf_nbr = matchstr( s:dbext_buffers_with_dict_files, '\<\d\+' )
    endwhile

    " Switch back to the current buffer
    silent! exec cur_buf.'buffer'
endfunction "}}}
function! s:DB_auBufDelete(del_buf_nr) "{{{
    " This function will delete any temporary dictionary files that were 
    " created
    
    " If the buffer number being deleted is in the script
    " variable that lists all buffers that have temporary dictionary
    " files, then remove the temporary dictionary files
    if s:dbext_buffers_with_dict_files !~ '\<'.a:del_buf_nr.','
        return
    endif

    " Save the current buffer to switch back to
    let cur_buf = bufnr("%")
    " Switch to the buffer being deleted
    silent! exec a:del_buf_nr.'buffer'

    call s:DB_DictionaryDelete( 'Table' )
    call s:DB_DictionaryDelete( 'Procedure' )
    call s:DB_DictionaryDelete( 'View' )

    " Switch back to the current buffer
    silent! exec cur_buf.'buffer'
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
" runPrevCmd {{{
function! s:DB_runPrevCmd(sql)
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
        " Rerun the SQL command
        call s:DB_execSql(a:sql)
    endif

    if curr_bufnr != switched_bufnr
        " Return to the original window
        exec s:dbext_prev_winnr."wincmd w"
        " Change the buffer (assuming hidden is set) to the previous
        " buffer.
        exec switched_bufnr."buffer"
    endif
endfunction "}}}
" runCmd {{{
function! s:DB_runCmd(cmd, sql)
    let s:dbext_prev_sql   = a:sql

    if has('win32unix') && s:DB_get('use_win32_filenames') == 1
    endif

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

        let result = system(a:cmd)

        call s:DB_addToResultBuffer(result, "add")

        " If there was an error, show the command just executed
        " for debugging purposes
        if v:shell_error
            let output = "To change connection parameters:\n" .
                        \ ":DBPromptForParameters\n" .
                        \ "Or\n" .
                        \ ":DBSetOption user\|passwd\|dsnname\|srvname\|dbname\|host\|port\|...=<value>\n" .
                        \ ":DBSetOption user=tiger:passwd=scott\n" .
                        \ "Last command(rc=".v:shell_error."):\n" .
                        \ a:cmd . "\n" .
                        \ "Last SQL:\n" .
                        \ a:sql . "\n" 
            call s:DB_addToResultBuffer(output, "add")
        else
            if exists('*DBextPostResult') 
                let res_buf_name   = s:DB_resBufName()
                if s:DB_switchToBuffer(res_buf_name, res_buf_name, 'result_bufnr') == 1
                    " Switch back to the result buffer and execute
                    " the user defined function
                    call DBextPostResult(s:DB_get('type'), s:DB_get('result_bufnr'))
                endif
            endif
        endif

        " Return to original window
        exec s:dbext_prev_winnr."wincmd w"
    else " Don't use result buffer
        if l:display_cmd_line == 1
            echo cmd_line
        endif

        let result = system(a:cmd)

        " If there was an error, return -1
        " and display a message informing the user.  This is necessary
        " when using sqlComplete, or things slightly fail.
        if v:shell_error
            echo 'dbext:'.result
            let result = '-1'
        endif

        return result
    endif

    return
endfunction "}}}
" switchToBuffer {{{
function! s:DB_switchToBuffer(buf_name, buf_file, get_buf_nr_name)
    " Retieve this value before we switch buffers
    let l:buffer_lines = s:DB_get('buffer_lines')

    " Do not use bufexists(res_buf_name), since it uses a fully qualified
    " path name to search for the buffer, which in effect opens multiple
    " buffers called "Result" if the files that you are executing the
    " commands from are in different directories.

    " Get the previously stored buffer number
    let buf_nr_str  = s:DB_get(a:get_buf_nr_name)
    " The buffer number may not have been initialized, so we must
    " handle this case.
    " bufexists takes a numeric argument, so we must add 0 to it
    " to convince Vim we are passing a numeric argument, if not
    " bufexists returns an unexpected value
    let buf_nr      = (buf_nr_str==''?-1:(buf_nr_str+0))
    let buf_exists  = bufexists(buf_nr)

    if buf_exists != 1
        call s:DB_set(a:get_buf_nr_name, -1)
    endif

    if bufwinnr(buf_nr) == -1
        " if the buffer is not visible, wipe it out and recreate it,
        " this will position us in the new buffer
        " exec 'bwipeout! ' . res_buf_nbr
        " silent exec 'bot ' . l:buffer_lines . 'new ' . res_buf_name
        silent exec 'bot ' . l:buffer_lines . 'split '
        exec ":silent! e " . escape(a:buf_file, ' ')
        call s:DB_set(a:get_buf_nr_name, bufnr('%'))
    else
        " If the buffer is visible, switch to it
        exec bufwinnr(buf_nr) . "wincmd w"
    endif

    return 1
endfunction "}}}
" closeWindow {{{
function! s:DB_closeWindow(buf_name)
    if a:buf_name == '%'
        " The user hit 'q', which is a buffer specific mapping to close
        " the result or history window.  Save the size of the buffer
        " for future use.
        
        " Update the local buffer variables with the current size
        " of the window, when we open it again we will use it's
        " size instead of the default
        call s:DB_set('buffer_lines', winheight(a:buf_name))
        
        " Hide it 
        hide
    else
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

            " If the buffer is visible, switch to it
            exec bufwinnr(res_buf_nbr) . "wincmd w"

            " Hide it 
            hide
        endif
    endif
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
" addToResultBuffer {{{
function! s:DB_addToResultBuffer(output, do_clear)
    " Store current window number so we can return to it
    " let cur_winnr      = winnr()
    let res_buf_name   = s:DB_resBufName()
    let conn_props     = s:DB_getTitle()

    " First close the history window if already open
    call s:DB_closeWindow(s:DB_get('history_bufname'))
    call s:DB_saveSize(res_buf_name)

    " Open buffer in required location
    if s:DB_switchToBuffer(res_buf_name, res_buf_name, 'result_bufnr') == 1
        nnoremap <buffer> <silent> R :DBRefreshResult<CR>
    endif

    setlocal modified
    " Create a buffer mapping to clo this window
    nnoremap <buffer> q :DBCloseResults<cr>
    " Delete all the lines prior to this run
    if a:do_clear == "clear" 
        %d
        silent! exec "normal! iConnection: " . conn_props . "\<Esc>0"
    endif

    if strlen(a:output) > 0
        " Add to end of buffer
        silent! exec "normal! G"
        silent! exec "put = a:output"
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

    " Return to original window
    " exec cur_winnr."wincmd w"
    exec s:dbext_prev_winnr."wincmd w"

    return
endfunction "}}}
" Parsers {{{
function! s:DB_parseQuery(query)
    " Reset this per query, the user can choose to stop prompting
    " at any time and this should stop for each of the different
    " options in variable_def
    call s:DB_set("stop_prompt_for_variables", 0)

    if &filetype == "sql"
        " Dont parse the SQL query, since DB_parseHostVariables
        " will pickup the standard host variables for prompting.
        " let query = s:DB_parseSQL(a:query)
        return s:DB_parseHostVariables(a:query)
    elseif &filetype == "java" || 
                \ &filetype == "jsp"  || 
                \ &filetype == "html"  || 
                \ &filetype == "javascript" 
        let query = s:DB_parseJava(a:query)
        return s:DB_parseHostVariables(query)
    elseif &filetype == "jproperties" 
        let query = s:DB_parseJProperties(a:query)
        return s:DB_parseHostVariables(query)
    elseif &filetype == "perl"
        " The Perl parser will deal with string concatenation
        let query = s:DB_parsePerl(a:query)
        " Let the SQL parser handle embedded host variables
        return s:DB_parseHostVariables(query)
    elseif &filetype == "php"
        let query = s:DB_parsePHP(a:query)
        return s:DB_parseHostVariables(query)
    elseif &filetype == "vim"
        let query = s:DB_parseVim(a:query)
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
        let count_nbr = count_nbr + 1
        " Retrieve the name of what we found
        let var = matchstr(str, a:exp_get_value, index)
        let index = index + 1
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
        if response == 1
            " Skip this match and move on to the next
            let index = match(str, a:exp_find_str, index+strlen(var))
        elseif response == 2
            " Use blank
            " Replace the variable with what was entered
            let replace_sub = '\%'.index.'c'.'.\{'.strlen(var).'}'
            let str = substitute(str, replace_sub, var_val, '')
            let index = match(str, a:exp_find_str, index+strlen(var_val))
        elseif response == 4
            " Never Prompt
            call s:DB_set("always_prompt_for_variables", "-1")
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
    endwhile
    return str
endfunction 
"}}}

" Host Variable Parser {{{
function! s:DB_parseHostVariables(query)
    let query = a:query

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
                    \ '\c\%(\<\%(insert\|merge\)\s\+\)\@<!INTO.\{-}FROM', 
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
    "   "SELECT * FROM " + prefix+"product"
    "   "SELECT * FROM " + obj.method() +"product"
    "   "SELECT * FROM " . method() ."product"
    let var_expr = '"\s*\(+\|\.\)\s*\(.\{-}\)\s*\(+\|\.\)\s*"'
    "  "\s*       - Double quote followed any space 
    "  \(+\|\.\)  - A plus sign or period
    "  \s*        - Any space
    "  \(.\{-}\)  - The variable / obj / method
    "  \s*        - Any space
    "  \(+\|\.\)  - A plus sign or period
    "  \s*"       - Any space followed by a double quote
    let query = s:DB_searchReplace(query, var_expr, var_expr, 0)

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
    call s:DB_resetBufferParameters(no_defaults)

    if profile_value =~? 'profile'
        let rc = -1
        call s:DB_warningMsg('dbext: Profiles cannot be nested' )
        return -1
    endif

    let rc = s:DB_setMultipleOptions(profile_value)

    return rc
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

    call s:DB_runPrevCmd(sql)
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

function! s:DB_historyList()
    let s:dbext_prev_winnr = winnr()
    let s:dbext_prev_bufnr = bufnr('%')

    call s:DB_historyOpen()

    " Create a mapping to act upon the history
    nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>DB_historyUse(line("."))<CR>
    nnoremap <buffer> <silent> <CR>          :call <SID>DB_historyUse(line("."))<CR>
    nnoremap <buffer> <silent> dd            :call <SID>DB_historyDel(line("."))<CR>
    " Create a buffer mapping to clo this window
    nnoremap <buffer> q :DBCloseResults<cr>
    nnoremap <buffer> R :DBRefreshResult<cr>
    
    " Go to top of output
    norm 2gg
endfunction 

function! s:DB_historyOpen()
    let res_buf_name   = s:DB_resBufName()
    " First close the result window if already open
    call s:DB_closeWindow(res_buf_name)
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

    if a:auto_hide == 1
        silent! hide
    endif

endfunction 

"}}}
call s:DB_buildLists()
call s:DB_resetGlobalParameters()
augroup dbext
    au!
    autocmd BufEnter    * call s:DB_setTitle()
    autocmd BufReadPost * if &modeline == 1 | call s:DB_checkModeline() | endif
    autocmd BufDelete   * call s:DB_auBufDelete( bufnr(expand("<afile>")) )
    autocmd VimLeavePre * call s:DB_auVimLeavePre()
augroup END
" vim:fdm=marker:nowrap:ts=4:expandtab:
