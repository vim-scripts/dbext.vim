" dbext.vim - Common Database Utility
" ---------------------------------------------------------------
" Version:  2.00
" Author:   Peter Bagyinszki <petike1@dpg.hu>
" CoAuthor: David Fisburn <fishburn@ianywhere.com>
" Last Modified: Sun Feb 08 2004 9:02:12 PM
" Based On: sqlplus.vim (author: Jamis Buck <jgb3@email.byu.edu>)
" Created:  2002-05-24
" Homepage: http://vim.sourceforge.net/script.php?script_id=356
" Contributors:  Joerg Schoppet <joerg.schoppet@web.de>
"                Hari Krishna Dara <hari_vim@yahoo.com>
" Dependencies:
"   - Requires multvals.vim to be installed. Download from:
"       http://www.vim.org/script.php?script_id=171
"
" SourceForge: $Revision: 1.14 $

if exists('g:loaded_dbext') || &cp
    finish
endif
if !exists("loaded_multvals")
  runtime plugin/multvals.vim
endif
if !exists("loaded_multvals") || loaded_multvals < 304
    echomsg "dbext: You need to have multvals version 3.4 or higher"
    finish
endif
let g:loaded_dbext = 200

" Script variable defaults {{{
let s:mv_sep = ","
let s:dbext_buffers_with_dict_files = ''
let s:unique_cnt = 0
" }}}

" Build internal lists {{{
function! s:DB_buildLists()
    " Available DB types
    let s:db_types_mv = ''
    "sybase adaptive server anywhere (fishburn)
    let s:db_types_mv = MvAddElement(s:db_types_mv, s:mv_sep, 'ASA')
    "sybase adaptive server enterprise (fishburn)
    let s:db_types_mv = MvAddElement(s:db_types_mv, s:mv_sep, 'ASE')
    "db2 (fishburn)
    let s:db_types_mv = MvAddElement(s:db_types_mv, s:mv_sep, 'DB2')
    "ingres (schoppet)
    let s:db_types_mv = MvAddElement(s:db_types_mv, s:mv_sep, 'INGRES')
    "interbase (bagyinszki)
    let s:db_types_mv = MvAddElement(s:db_types_mv, s:mv_sep, 'INTERBASE')
    "mysql (bagyinszki)
    let s:db_types_mv = MvAddElement(s:db_types_mv, s:mv_sep, 'MYSQL')
    "oracle (fishburn)
    let s:db_types_mv = MvAddElement(s:db_types_mv, s:mv_sep, 'ORA')
    "postgresql (bagyinszki)
    let s:db_types_mv = MvAddElement(s:db_types_mv, s:mv_sep, 'PGSQL')
    "microsoft sql server (fishburn)
    let s:db_types_mv = MvAddElement(s:db_types_mv, s:mv_sep, 'SQLSRV')

    " Connection parameters
    let s:conn_params_mv = ''
    let s:conn_params_mv = MvAddElement(s:conn_params_mv, s:mv_sep, 'profile')
    let s:conn_params_mv = MvAddElement(s:conn_params_mv, s:mv_sep, 'type')
    let s:conn_params_mv = MvAddElement(s:conn_params_mv, s:mv_sep, 'user')
    let s:conn_params_mv = MvAddElement(s:conn_params_mv, s:mv_sep, 'passwd')
    let s:conn_params_mv = MvAddElement(s:conn_params_mv, s:mv_sep, 'dsnname')
    let s:conn_params_mv = MvAddElement(s:conn_params_mv, s:mv_sep, 'srvname')
    let s:conn_params_mv = MvAddElement(s:conn_params_mv, s:mv_sep, 'dbname')
    let s:conn_params_mv = MvAddElement(s:conn_params_mv, s:mv_sep, 'host')
    let s:conn_params_mv = MvAddElement(s:conn_params_mv, s:mv_sep, 'port')
    let s:conn_params_mv = MvAddElement(s:conn_params_mv, s:mv_sep, 'bin_path')

    " Configuration parameters
    let s:config_params_mv = ''
    let s:config_params_mv = MvAddElement(s:config_params_mv, s:mv_sep, 'use_result_buffer')
    let s:config_params_mv = MvAddElement(s:config_params_mv, s:mv_sep, 'use_sep_result_buffer')
    let s:config_params_mv = MvAddElement(s:config_params_mv, s:mv_sep, 'buffer_lines')
    let s:config_params_mv = MvAddElement(s:config_params_mv, s:mv_sep, 'parse_statements')
    let s:config_params_mv = MvAddElement(s:config_params_mv, s:mv_sep, 'prompt_for_parameters')
    let s:config_params_mv = MvAddElement(s:config_params_mv, s:mv_sep, 'prompting_user')
    let s:config_params_mv = MvAddElement(s:config_params_mv, s:mv_sep, 'always_prompt_for_variables')
    let s:config_params_mv = MvAddElement(s:config_params_mv, s:mv_sep, 'display_cmd_line')
    let s:config_params_mv = MvAddElement(s:config_params_mv, s:mv_sep, 'variable_def')
    let s:config_params_mv = MvAddElement(s:config_params_mv, s:mv_sep, 'buffer_defaulted')
    let s:config_params_mv = MvAddElement(s:config_params_mv, s:mv_sep, 'dict_table_file')
    let s:config_params_mv = MvAddElement(s:config_params_mv, s:mv_sep, 'dict_procedure_file')
    let s:config_params_mv = MvAddElement(s:config_params_mv, s:mv_sep, 'dict_view_file')

    " DB server specific params
    let s:db_params_mv = ''
    let s:db_params_mv = MvAddElement(s:db_params_mv, s:mv_sep, 'bin')
    let s:db_params_mv = MvAddElement(s:db_params_mv, s:mv_sep, 'cmd_header')
    let s:db_params_mv = MvAddElement(s:db_params_mv, s:mv_sep, 'cmd_terminator')
    let s:db_params_mv = MvAddElement(s:db_params_mv, s:mv_sep, 'cmd_options')
    let s:db_params_mv = MvAddElement(s:db_params_mv, s:mv_sep, 'on_error')

    " All parameters
    let s:all_params_mv = ''

    call MvIterCreate(s:conn_params_mv, s:mv_sep, "MvConnParams", s:mv_sep)
    while MvIterHasNext('MvConnParams')
        let s:all_params_mv = MvAddElement(s:all_params_mv, s:mv_sep, MvIterNext('MvConnParams'))
    endwhile
    call MvIterDestroy("MvConnParams")

    call MvIterCreate(s:config_params_mv, s:mv_sep, "MvConfigParams", s:mv_sep)
    while MvIterHasNext('MvConfigParams')
        let s:all_params_mv = MvAddElement(s:all_params_mv, s:mv_sep, MvIterNext('MvConfigParams'))
    endwhile
    call MvIterDestroy("MvConfigParams")

    call MvIterCreate(s:db_params_mv, s:mv_sep, "MvDBParams", s:mv_sep)
    while MvIterHasNext('MvDBParams')
        let s:all_params_mv = MvAddElement(s:all_params_mv, s:mv_sep, MvIterNext('MvDBParams'))
    endwhile
    call MvIterDestroy("MvDBParams")

    let loop_count         = 0
    let s:prompt_type_list = "\n0. None\n"

    call MvIterCreate(s:db_types_mv, s:mv_sep, "MvDBTypes", s:mv_sep)
    while MvIterHasNext('MvDBTypes')
        let type_mv = MvIterNext('MvDBTypes')
        let loop_count = loop_count + 1
        let s:prompt_type_list = s:prompt_type_list . loop_count . '. ' . type_mv . "\n"
        call MvIterCreate(s:db_params_mv, s:mv_sep, "MvDBParams", s:mv_sep)
        while MvIterHasNext('MvDBParams')
            let s:all_params_mv = MvAddElement(s:all_params_mv, s:mv_sep, MvIterNext('MvDBParams'))
        endwhile
        call MvIterDestroy("MvDBParams")
    endwhile
    call MvIterDestroy("MvDBTypes")

    " Any predefined global connection profiles in the users vimrc
    let s:conn_profiles_mv    = ''
    let loop_count            = 1
    let s:prompt_profile_list = ''


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
            let s:prompt_profile_list = s:prompt_profile_list . "\n" .
                        \  loop_count . '. ' . prof_name
            let prof_value = matchstr(l:global_vars, '\s*\zs[^'."\<C-J>".']\+', 
                        \ (index + strlen(prof_name))  )
            let s:conn_profiles_mv = MvAddElement(s:conn_profiles_mv, s:mv_sep, prof_name)
            let loop_count = loop_count + 1
        endif
        let index = index + strlen(prof_name)+ strlen(prof_value) + 1
        let index = match(l:global_vars, prof_nm_re, index)
    endwhile
    if loop_count > 1
        let s:prompt_profile_list = "\n0. None" . s:prompt_profile_list
    endif

endfunction 
"}}}

" Configuration {{{
"" Execute function, but prompt for parameters if necessary
function! s:DB_execFuncWCheck(name,...)
    let use_defaults = 1
    if s:DB_get("buffer_defaulted") != 1
        call s:DB_resetBufferParameters(use_defaults)
        if s:DB_get("buffer_defaulted") != 1
            call s:DB_warningMsg( "A valid database type must be chosen" )
            return
        elseif a:name == 'promptForParameters'
            " Handle the special case where no parameters were defaulted
            " but the process of resettting them has defaulted them.
            call s:DB_warningMsg( "Connection parameters have been defaulted" )
            return
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
    let use_defaults = 1
    if s:DB_get("buffer_defaulted") != 1
        call s:DB_resetBufferParameters(use_defaults)
        if s:DB_get("buffer_defaulted") != 1
            call s:DB_warningMsg( "A valid database type must be chosen" )
            return
        endif
    endif

    if !exists("*s:DB_".b:dbext_type."_".a:name)
        let value = toupper(b:dbext_type)
        if !MvContainsElement(s:db_types_mv, s:mv_sep, value)
            call s:DB_warningMsg("Unknown database type: " . b:dbext_type)
            return ""
        else
            call s:DB_warningMsg( "s:DB_" . b:dbext_type .
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

"" Set buffer parameter value
function! s:DB_set(name, value)
    if MvContainsElement(s:all_params_mv, s:mv_sep, a:name)
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

        let b:dbext_{a:name} = value
    else
        call s:DB_warningMsg("Unknown parameter: " . a:name)
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

"" Get buffer parameter value
function! s:DB_get(name, ...)
    " Use defaults as the default for this function
    let use_defaults = ((a:0 > 0)?(a:1+0):1)
    let no_default   = 0

    if exists("b:dbext_".a:name)
        let retval = b:dbext_{a:name} . '' "force string
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
    if a:name ==# "profile"                 |return (exists("g:dbext_default_profile")?g:dbext_default_profile.'':'@askb') | else
    if a:name ==# "type"                    |return (exists("g:dbext_default_type")?g:dbext_default_type.'':'@askb') |else
    if a:name ==# "user"                    |return (exists("g:dbext_default_user")?g:dbext_default_user.'':'@askb') |else
    if a:name ==# "passwd"                  |return (exists("g:dbext_default_passwd")?g:dbext_default_passwd.'':'@askb') |else
    " ? - look for a question mark
    " w - MUST have word characters after it
    " W - CANNOT have any word characters after it
    " q - quotes do not matter
    " Q - CANNOT be surrounded in quotes
    " , - delimiter between options
    if a:name ==# "variable_def"            |return (exists("g:dbext_default_variable_def")?g:dbext_default_variable_def.'':'?WQ,@wq,:wq,$wq') |else
    if a:name ==# "buffer_lines"            |return (exists("g:dbext_default_buffer_lines")?g:dbext_default_buffer_lines.'':5) | else
    if a:name ==# "use_result_buffer"       |return (exists("g:dbext_default_use_result_buffer")?g:dbext_default_use_result_buffer.'':1) | else
    if a:name ==# "use_sep_result_buffer"   |return (exists("g:dbext_default_use_sep_result_buffer")?g:dbext_default_use_sep_result_buffer.'':0) | else
    if a:name ==# "display_cmd_line"        |return (exists("g:dbext_default_display_cmd_line")?g:dbext_default_display_cmd_line.'':0) | else
    if a:name ==# "prompt_for_parameters"   |return (exists("g:dbext_default_prompt_for_parameters")?g:dbext_default_prompt_for_parameters.'':1) | else
    if a:name ==# "parse_statements"        |return (exists("g:dbext_default_parse_statements")?g:dbext_default_parse_statements.'':'select,update,delete,insert,call,exec') | else
    if a:name ==# "always_prompt_for_variables" |return (exists("g:dbext_default_always_prompt_for_variables")?g:dbext_default_always_prompt_for_variables.'':0) | else
    if a:name ==# "ASA_bin"                 |return (exists("g:dbext_default_ASA_bin")?g:dbext_default_ASA_bin.'':'dbisql') |else
    if a:name ==# "ASA_cmd_terminator"      |return (exists("g:dbext_default_ASA_cmd_terminator")?g:dbext_default_ASA_cmd_terminator.'':';') | else
    if a:name ==# "ASA_cmd_options"         |return (exists("g:dbext_default_ASA_cmd_options")?g:dbext_default_ASA_cmd_options.'':'-nogui') |else
    if a:name ==# "ASE_bin"                 |return (exists("g:dbext_default_ASE_bin")?g:dbext_default_ASE_bin.'':'isql') |else
    if a:name ==# "ASE_cmd_terminator"      |return (exists("g:dbext_default_ASE_cmd_terminator")?g:dbext_default_ASE_cmd_terminator.'':"\ngo\n") |else
    if a:name ==# "ASE_cmd_options"         |return (exists("g:dbext_default_ASE_cmd_options")?g:dbext_default_ASE_cmd_options.'':'-w 10000') |else
    if a:name ==# "DB2_bin"                 |return (exists("g:dbext_default_DB2_bin")?g:dbext_default_DB2_bin.'':'db2batch') |else
    if a:name ==# "DB2_cmd_options"         |return (exists("g:dbext_default_DB2_cmd_options")?g:dbext_default_DB2_cmd_options.'':'-q off -s off') |else
    if a:name ==# "DB2_cmd_terminator"      |return (exists("g:dbext_default_DB2_cmd_terminator")?g:dbext_default_DB2_cmd_terminator.'':';') | else
    if a:name ==# "INGRES_bin"              |return (exists("g:dbext_default_INGRES_bin")?g:dbext_default_INGRES_bin.'':'sql') | else
    if a:name ==# "INGRES_cmd_terminator"   |return (exists("g:dbext_default_INGRES_cmd_terminator")?g:dbext_default_INGRES_cmd_terminator.'':'\p\g') |else
    if a:name ==# "INTERBASE_bin"           |return (exists("g:dbext_default_INTERBASE_bin")?g:dbext_default_INTERBASE_bin.'':'isql') |else
    if a:name ==# "INTERBASE_cmd_terminator"|return (exists("g:dbext_default_INTERBASE_cmd_terminator")?g:dbext_default_INTERBASE_cmd_terminator.'':';') |else
    if a:name ==# "MYSQL_bin"               |return (exists("g:dbext_default_MYSQL_bin")?g:dbext_default_MYSQL_bin.'':'mysql') |else
    if a:name ==# "MYSQL_cmd_terminator"    |return (exists("g:dbext_default_MYSQL_cmd_terminator")?g:dbext_default_MYSQL_cmd_terminator.'':';') |else
    if a:name ==# "ORA_bin"                 |return (exists("g:dbext_default_ORA_bin")?g:dbext_default_ORA_bin.'':'sqlplus') |else
    if a:name ==# "ORA_cmd_header"          |return (exists("g:dbext_default_ORA_cmd_header")?g:dbext_default_ORA_cmd_header.'':"" .
                        \ "set pagesize 10000\n" .
                        \ "set wrap off\n" .
                        \ "set sqlprompt \"\"\n" .
                        \ "set flush off\n" .
                        \ "set colsep \"\t\"\n" .
                        \ "set tab off\n\n") |else
    if a:name ==# "ORA_cmd_options"         |return (exists("g:dbext_default_ORA_cmd_options")?g:dbext_default_ORA_cmd_options.'':"-S") |else
    if a:name ==# "ORA_cmd_terminator"      |return (exists("g:dbext_default_ORA_cmd_terminator")?g:dbext_default_ORA_cmd_terminator.'':";\nquit;") |else
    if a:name ==# "PGSQL_bin"               |return (exists("g:dbext_default_PGSQL_bin")?g:dbext_default_PGSQL_bin.'':'psql') |else
    if a:name ==# "PGSQL_cmd_terminator"    |return (exists("g:dbext_default_PGSQL_cmd_terminator")?g:dbext_default_PGSQL_cmd_terminator.'':';') |else
    if a:name ==# "SQLSRV_bin"              |return (exists("g:dbext_default_SQLSRV_bin")?g:dbext_default_SQLSRV_bin.'':'isql') |else
    if a:name ==# "SQLSRV_cmd_options"      |return (exists("g:dbext_default_SQLSRV_cmd_options")?g:dbext_default_SQLSRV_cmd_options.'':'-w 10000 -r -b') |else
    if a:name ==# "prompt_profile"          |return (exists("g:dbext_default_prompt_profile")?g:dbext_default_prompt_profile.'':"" .
                \ "[Optional] Enter profile name: ".s:prompt_profile_list) |else
    if a:name ==# "prompt_type"             |return (exists("g:dbext_default_prompt_type")?g:dbext_default_prompt_type.'':"" .
                \ "\nPlease choose # of database type: ".s:prompt_type_list) |else
    if a:name ==# "prompt_user"             |return (exists("g:dbext_default_prompt_user")?g:dbext_default_prompt_user.'':'[Optional] Database user: ') |else
    if a:name ==# "prompt_passwd"           |return (exists("g:dbext_default_prompt_passwd")?g:dbext_default_prompt_passwd.'':'[O] User password: ') |else
    if a:name ==# "prompt_dsnname"          |return (exists("g:dbext_default_prompt_dsnname")?g:dbext_default_prompt_dsnname.'':'[O] ODBC DSN: ') |else
    if a:name ==# "prompt_srvname"          |return (exists("g:dbext_default_prompt_srvname")?g:dbext_default_prompt_srvname.'':'[O] Server name: ') |else
    if a:name ==# "prompt_dbname"           |return (exists("g:dbext_default_prompt_dbname")?g:dbext_default_prompt_dbname.'':'[O] Database name: ') |else
    if a:name ==# "prompt_host"             |return (exists("g:dbext_default_prompt_host")?g:dbext_default_prompt_host.'':'[O] Host name: ') |else
    if a:name ==# "prompt_port"             |return (exists("g:dbext_default_prompt_port")?g:dbext_default_prompt_port.'':'[O] Port name: ') |else
    if a:name ==# "prompt_bin_path"         |return (exists("g:dbext_default_prompt_bin_path")?g:dbext_default_prompt_bin_path.'':'[O] Directory for database tools: ') |else
    " These are for name completion using Vim's dictionary feature
    if a:name ==# "dict_table_file"         |return '' |else
    if a:name ==# "dict_procedure_file"     |return '' |else
    if a:name ==# "dict_view_file"          |return '' |else

    return ""
                " \nPlease choose database type (from above ie ASA): ") |else
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

    " If a database type has been chosen, do not prompt
    " for connection information
    if s:db_types_mv =~ s:DB_get("type", no_defaults) &&
                \ strlen(s:DB_get("type", no_defaults)) > 0
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
    call MvIterCreate(s:config_params_mv, s:mv_sep, "MvConfigParams")
    while MvIterHasNext('MvConfigParams')
        let param = MvIterNext('MvConfigParams')
        call s:DB_set(param, s:DB_get(param))
    endwhile
    call MvIterDestroy("MvConfigParams")

    " Reset connection parameters to either blanks or defaults
    " depending on what was passed into this function
    " Loop through and prompt the user for all buffer
    " connection parameters.
    " Calling this function can be nested, so we must generate
    " a unique IterCreate name.
    let l:iter_unique_name = "MvConnParamsRBP".s:unique_cnt
    let s:unique_cnt = s:unique_cnt + 1
    call MvIterCreate(s:conn_params_mv, s:mv_sep, l:iter_unique_name)
    while MvIterHasNext(l:iter_unique_name)
        let param = MvIterNext(l:iter_unique_name)
        if a:use_defaults == 0
            call s:DB_set(param, "")
        else
            " Only set the buffer variable if the default value
            " is not '@ask'
            if s:DB_getDefault(param) !=? '@ask'
                call s:DB_set(param, s:DB_get(param))
            endif
        endif
    endwhile
    call MvIterDestroy(l:iter_unique_name)

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
        call s:DB_warningMsg("Invalid scope in parameter: '" . a:scope . "'")
        return ""
    endif
    let variables = ""

    call MvIterCreate(s:all_params_mv, s:mv_sep, "MvAllParams")
    while MvIterHasNext('MvAllParams')
        let param = MvIterNext('MvAllParams')
        let variables = variables . s:DB_varToString(prefix . param)
    endwhile
    call MvIterDestroy("MvAllParams")

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
    call MvIterCreate(s:conn_params_mv, s:mv_sep, "MvConnParams")
    while MvIterHasNext('MvConnParams')
        let param = MvIterNext('MvConnParams')

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
                        \ MvIndexOfElement(s:db_types_mv, s:mv_sep, 
                        \ s:DB_get(param, no_default) 
                        \ )

            let l:new_value = s:DB_getInput( 
                        \ s:DB_getDefault("prompt_" . param), 
                        \ l:old_value,
                        \ "-1"
                        \ )
        elseif param ==# 'profile'
            if MvNumberOfElements(s:conn_profiles_mv, s:mv_sep) == 0
                continue
            endif

            let l:old_value = 1 + 
                        \ MvIndexOfElement(s:conn_profiles_mv, s:mv_sep, 
                        \ s:DB_get(param, no_default) 
                        \ )

            let l:new_value = s:DB_getInput( 
                        \ s:DB_getDefault("prompt_" . param), 
                        \ l:old_value,
                        \ "-1"
                        \ )
        else
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
        elseif l:new_value != l:old_value
            let retval = l:new_value

            if l:old_value =~ '@askg'
                " Handle the special case of setting a global (@askg) value.
                " There is no need to do something for the buffer (@askb) 
                " since all changes affect the buffer variables.
                call s:DB_setGlobal(param, l:new_value)
            endif

            if param == "profile"
                if l:new_value > 0 && l:new_value <= 
                            \ MvNumberOfElements(s:conn_profiles_mv, s:mv_sep)
                    let retval = MvElementAt(s:conn_profiles_mv, s:mv_sep, 
                                \ (l:new_value-1))
                    call s:DB_set(param, retval)
                else
                    call s:DB_set(param, "")
                endif

                if strlen(s:DB_get('type')) > 0
                    break
                endif
            elseif param == "type"
                if l:new_value > 0 && l:new_value <= 
                            \ MvNumberOfElements(s:db_types_mv, s:mv_sep)
                    let retval = MvElementAt(s:db_types_mv, s:mv_sep, 
                                \ (l:new_value-1))
                    call s:DB_set(param, retval)
                else
                    call s:DB_set(param, "") 
                endif
            else
                if l:old_value ==? '@ask'
                    " If the default value is @ask, then do not set the 
                    " buffer parameter, just return the value.
                    " The next time we execute something, we will be
                    " prompted for this value again.
                    break
                endif

                call s:DB_set(param, l:new_value) 

            endif
        endif
    endwhile
    call MvIterDestroy("MvConnParams")

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
    let options_mv = s:DB_stripLeadFollowQuotesSpace(a:multi_options)

    " Loop through and prompt the user for all buffer
    " connection parameters.
    " Calling this function can be nested, so we must generate
    " a unique IterCreate name.
    let l:iter_unique_name = "MvOptions".s:unique_cnt
    let s:unique_cnt = s:unique_cnt + 1
    " echomsg 'DB_setMultipleOptions: unique name:' . l:iter_unique_name
    call MvIterCreate(options_mv, ":", l:iter_unique_name)
    while MvIterHasNext(l:iter_unique_name)
        let option = MvIterNext(l:iter_unique_name)
        if strlen(option) > 0
            " Retrieve the option name 
            " let option    = substitute(option_pad, '\s*\(.*\)\s*', '\1', '')
            let opt_name  = matchstr(option, '.\{-}\ze=')
            let opt_value = matchstr(option, '=\zs.*')
            " let opt_value = substitute(opt_value, '\s*$', '', 'g')
            let opt_value = s:DB_stripLeadFollowQuotesSpace(opt_value)
            " if opt_value  =~ ';'
            "     let rc = -1
            "     call s:DB_warningMsg('dbext: Option: ' . opt_name .
            "                 \ " Value: " . opt_value . " - cannot have ;'s")
            "     break
            " endif
            call s:DB_set(opt_name, opt_value)
        endif
    endwhile
    call MvIterDestroy(l:iter_unique_name)

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
                "\ :call s:DB_promptForParameters()
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
    if output !~ s:DB_getWType("cmd_terminator") . '[^\n\s]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    let tempfile = tempname()
    exe 'redir! > ' . tempfile
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
    let cmd = dbext_bin .  ' ' . s:DB_getWType("cmd_options")
    if (s:DB_get("on_error") == "")
        let cmd = s:DB_option(cmd, ' -onerror exit', '')
    else
        let cmd = s:DB_option(cmd, ' -onerror ' . s:DB_get("on_error"), '')
    endif
    let cmd = cmd . ' -c "' .
                \ s:DB_option('uid=', s:DB_get("user"), ';') .
                \ s:DB_option('pwd=', s:DB_get("passwd"), ';') .
                \ s:DB_option('dsn=', s:DB_get("dsnname"), ';') .
                \ s:DB_option('eng=', s:DB_get("srvname"), ';') .
                \ s:DB_option('dbn=', s:DB_get("dbname"), ';') .
                \ s:DB_option('links=', links, ';') .
                \ '" ' . 
                \ ' read ' . tempfile
    let result = s:DB_runCmd(cmd, output)
    let rc = delete(tempfile)
    if rc != 0
        echo 'Failed to delete: ' . tempfile . ' rc: ' . rc
    endif
    return result
endfunction

function! s:DB_ASA_describeTable(table_name)
    return s:DB_ASA_execSql("call sp_jdbc_columns('".a:table_name."');")
endfunction

function! s:DB_ASA_describeProcedure(proc_name)
    return s:DB_ASA_execSql("call sp_sproc_columns('".a:proc_name."');")
endfunction

function! s:DB_ASA_getListTable(table_prefix)
    return s:DB_ASA_execSql("call sp_jdbc_tables('".a:table_prefix."%');")
endfunction

function! s:DB_ASA_getListProcedure(proc_prefix)
    return s:DB_ASA_execSql(
                \ "call sp_jdbc_stored_procedures(null, null, ".
                \ "'".a:proc_prefix."%');")
endfunction

function! s:DB_ASA_getListView(view_prefix)
    return s:DB_ASA_execSql(
                \ "SELECT viewname, vcreator ".
                \ " FROM SYSVIEWS ".
                \ " WHERE viewname LIKE '".a:view_prefix."%'"
                \ )
endfunction 

function! s:DB_ASA_getListColumn(table_name) 
    let owner      = s:DB_getObjectOwner(a:table_name)
    let table_name = s:DB_getObjectName(a:table_name)
    let query =   "SELECT column_name              " .
                \ "  FROM SYS.SYSTABLE st          " .
                \ "   KEY JOIN SYS.SYSCOLUMN sc    " .
                \ "   KEY JOIN sys.sysuserperm sup " .
                \ " WHERE st.table_name = '" . table_name . "'" 
    if strlen(owner) > 0
        let query = query .
                    \ "   AND sup.user_name = '".owner."' "
    endif
    let query = query .
                \ " ORDER BY column_id;            "
    let result = s:DB_ASA_execSql( query )
    return s:DB_ASA_stripHeaderFooter(result)
endfunction 

function! s:DB_ASA_stripHeaderFooter(result)
    " Strip off column headers ending with a newline
    " let stripped = substitute( a:result, '\_.*-\s*'."[\<C-V>\<C-J>]", '', '' )
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-J>]", '', '' )
    " Strip off query statistics
    let stripped = substitute( stripped, '(First \d\+ rows\_.*', '', '' )
    return stripped
endfunction 

function! s:DB_ASA_getDictionaryTable() 
    let result = s:DB_ASA_execSql(
                \ "SELECT table_name    " .
                \ "  FROM SYS.SYSTABLE  " .
                \ " ORDER BY table_name;"
                \ )
    return s:DB_ASA_stripHeaderFooter(result)
endfunction 

function! s:DB_ASA_getDictionaryProcedure() 
    let result = s:DB_ASA_execSql(
                \ "SELECT proc_name       " .
                \ " FROM SYS.SYSPROCEDURE " .
                \ " ORDER BY proc_name;   "
                \ )
    return s:DB_ASA_stripHeaderFooter(result)
endfunction 

function! s:DB_ASA_getDictionaryView() 
    let result = s:DB_ASA_execSql(
                \ "SELECT viewname     " .
                \ "  FROM SYS.SYSVIEWS " .
                \ " ORDER BY viewname; "
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
    if output !~ s:DB_getWType("cmd_terminator") . '[^\n\s]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    let tempfile = tempname()
    exe 'redir! > ' . tempfile
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
                \ ' -i ' . tempfile

    let result = s:DB_runCmd(cmd, output)
    let rc = delete(tempfile)
    if rc != 0
        echo 'Failed to delete: ' . tempfile . ' rc: ' . rc
    endif
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
    return stripped
endfunction "}}}

function! s:DB_ASE_getDictionaryTable() "{{{
    let result = s:DB_ASE_execSql(
                \ "select convert(varchar,o.name) ".
                \ "  from sysobjects o            ".
                \ " where o.type='U'              ".
                \ " order by o.name               "
                \ )
    return s:DB_ASE_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_ASE_getDictionaryProcedure() "{{{
    let result = s:DB_ASE_execSql(
                \ "select convert(varchar,o.name) ".
                \ "  from sysobjects o ".
                \ " where o.type='P' ".
                \ " order by o.name"
                \ )
    return s:DB_ASE_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_ASE_getDictionaryView() "{{{
    let result = s:DB_ASE_execSql(
                \ "select convert(varchar,o.name) ".
                \ "  from sysobjects o ".
                \ " where o.type='V' ".
                \ " order by o.name"
                \ )
    return s:DB_ASE_stripHeaderFooter(result)
endfunction "}}}
"}}}
" DB2 exec {{{
function! s:DB_DB2_execSql(str)
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let output = s:DB_getWType("cmd_header") . a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_getWType("cmd_terminator") . '[^\n\s]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    let tempfile = tempname()
    exe 'redir! > ' . tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . s:DB_getWType("cmd_options")
    if s:DB_get("user") != ""
        let cmd = cmd . ' -a ' . s:DB_get("user") . '/' .
                    \ s:DB_get("passwd") . ' '
    endif
    let cmd = cmd . 
                \ s:DB_option('-H ', s:DB_get("host"), ' ') .
                \ s:DB_option('-d ', s:DB_get("dbname"), ' ') .
                \ s:DB_option('-l ', s:DB_getWType("cmd_terminator"), ' ') .
                \ ' -f ' . tempfile
    let result = s:DB_runCmd(cmd, output)
    let rc = delete(tempfile)
    if rc != 0
        echo 'Failed to delete: ' . tempfile . ' rc: ' . rc
    endif
    return result
endfunction

function! s:DB_DB2_describeTable(table_name)
    let owner      = s:DB_getObjectOwner(a:table_name)
    let table_name = s:DB_getObjectName(a:table_name)
    " Another option is:
    " db2 describe table db2inst1.org
    let cmd = 'db2look'
    let cmd = cmd . ' '
    if b:dbext_user != ""
        let cmd = cmd . '-i ' . b:dbext_user . ' '
    endif
    if b:dbext_passwd != ""
        let cmd = cmd . '-w ' . b:dbext_passwd . ' '
    endif
    if owner != ""
        let cmd = cmd . '-u ' . owner . ' '
    elseif b:dbext_user != ""
        let cmd = cmd . '-u ' . b:dbext_user . ' '
    endif
    if b:dbext_dbname != ""
        let cmd = cmd . '-d ' . b:dbext_dbname . ' '
    endif
    let cmd = cmd . '-e -t ' . table_name
    " call Decho("Command: '". cmd . "'")
    " echom cmd
    return s:DB_runCmd(cmd, cmd)
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
                \ "     , CAST(definer AS VARCHAR(15)) AS definer " .
                \ "     , card " .
                \ " from syscat.tables ".
                \ " where tabname like '".a:table_prefix."%' ".
                \ " order by tabname")
endfunction

function! s:DB_DB2_getListProcedure(proc_prefix)
    return s:DB_DB2_execSql(
                \ "select CAST(procname AS VARCHAR(40)) AS procname " .
                \ "     , CAST(definer AS VARCHAR(15)) AS definer " .
                \ "     , parm_count " .
                \ "     , deterministic " .
                \ "     , fenced " .
                \ "     , result_sets " .
                \ " from syscat.procedures ".
                \ " where procname like '".a:proc_prefix."%' ".
                \ " order by procname")
endfunction

function! s:DB_DB2_getListView(view_prefix)
    return s:DB_DB2_execSql(
                \ "select CAST(viewname AS VARCHAR(40)) AS viewname " .
                \ "     , CAST(definer AS VARCHAR(15)) AS definer " .
                \ "     , readonly " .
                \ "     , valid " .
                \ " from syscat.views ".
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
    " Strip off column headers ending with a newline
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-J>]", '', '' )
    " Strip off query statistics
    let stripped = substitute( stripped, 'Number of rows\_.*', '', '' )
    return stripped
endfunction 

function! s:DB_DB2_getDictionaryTable()
    let result = s:DB_DB2_execSql( 
                \ "select CAST(tabname AS VARCHAR(40)) AS tabname " .
                \ " from syscat.tables                            " .
                \ " order by tabname                              " 
                \ )
    return s:DB_DB2_stripHeaderFooter(result)
endfunction 

function! s:DB_DB2_getDictionaryProcedure()
    let result = s:DB_DB2_execSql( 
                \ "select CAST(procname AS VARCHAR(40)) AS procname " .
                \ " from syscat.procedures                          " .
                \ " order by procname                               " 
                \ )
    return s:DB_DB2_stripHeaderFooter(result)
endfunction

function! s:DB_DB2_getDictionaryView() 
    let result = s:DB_DB2_execSql( 
                \ "select CAST(viewname AS VARCHAR(40)) AS viewname " .
                \ " from syscat.views                               " .
                \ " order by viewname                               " 
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
    if output !~ s:DB_getWType("cmd_terminator") . '[^\n\s]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    let tempfile = tempname()
    exe 'redir! > ' . tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . 
                \ s:DB_option('-S ', s:DB_get("dbname"), ' ') .
                \ s:DB_option('', s:DB_getWType("cmd_options"), ' ') .
                \ ' < ' . tempfile
    let result = s:DB_runCmd(cmd, output)
    let rc = delete(tempfile)
    if rc != 0
        echo 'Failed to delete: ' . tempfile . ' rc: ' . rc
    endif
    return result
endfunction

function! s:DB_INGRES_describeTable(table_name)
    return s:DB_INGRES_execSql("help " . a:table_name . ";")
endfunction

function! s:DB_INGRES_describeProcedure(procedure_name)
    echo 'Feature not yet available'
    " return s:DB_INGRES_execSql("help ".a:procedure_name.";")
endfunction

function! s:DB_INGRES_getListTable(table_prefix)
    echo 'Feature not yet available'
endfunction

function! s:DB_INGRES_getListProcedure(proc_prefix)
    echo 'Feature not yet available'
endfunction

function! s:DB_INGRES_getListView(view_prefix)
    echo 'Feature not yet available'
endfunction 

function! s:DB_INGRES_getListColumn(table_name) 
    echo 'Feature not yet available'
    return
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
    if output !~ s:DB_getWType("cmd_terminator") . '[^\n\s]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    let tempfile = tempname()
    exe 'redir! > ' . tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))

    let cmd = dbext_bin .  ' ' . 
                \ s:DB_option('-username ', s:DB_get("user"), ' ') .
                \ s:DB_option('-password ', s:DB_get("passwd"), ' ') .
                \ s:DB_option('', s:DB_getWType("cmd_options"), ' ') .
                \ '-input ' . tempfile .
                \ s:DB_option(' ', s:DB_get("dbname"), '')
    let result = s:DB_runCmd(cmd, output)
    let rc = delete(tempfile)
    if rc != 0
        echo 'Failed to delete: ' . tempfile . ' rc: ' . rc
    endif
    return result
endfunction

function! s:DB_INTERBASE_describeTable(table_name)
    return s:DB_INTERBASE_execSql("show table ".a:table_name.";")
endfunction

function! s:DB_INTERBASE_describeProcedure(procedure_name)
    echo 'Feature not yet available'
    " return s:DB_INTERBASE_execSql("show procedure ".a:procedure_name.";")
endfunction

function! s:DB_INTERBASE_getListTable(table_prefix)
    echo 'Feature not yet available'
endfunction

function! s:DB_INTERBASE_getListProcedure(proc_prefix)
    echo 'Feature not yet available'
endfunction

function! s:DB_INTERBASE_getListView(view_prefix)
    echo 'Feature not yet available'
endfunction 

function! s:DB_INTERBASE_getListColumn(table_name) 
    echo 'Feature not yet available'
    return
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
    if output !~ s:DB_getWType("cmd_terminator") . '[^\n\s]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    let tempfile = tempname()
    exe 'redir! > ' . tempfile
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
                \ ' < ' . tempfile
    let result = s:DB_runCmd(cmd, output)
    let rc = delete(tempfile)
    if rc != 0
        echo 'Failed to delete: ' . tempfile . ' rc: ' . rc
    endif
    return result
endfunction

function! s:DB_MYSQL_describeTable(table_name)
    return s:DB_MYSQL_execSql("describe ".a:table_name)
endfunction

function! s:DB_MYSQL_describeProcedure(procedure_name)
    echo 'Feature not yet available'
    " return s:DB_MYSQL_execSql("describe ".a:procedure_name)
endfunction

function! s:DB_MYSQL_getListTable(table_prefix)
    let query = "show tables like '" .
                \ a:table_prefix .
                \ "%'" 
    return s:DB_MYSQL_execSql(query)
endfunction

function! s:DB_MYSQL_getListProcedure(proc_prefix)
    echo 'Feature not yet available'
endfunction

function! s:DB_MYSQL_getListView(view_prefix)
    echo 'Feature not yet available'
endfunction 

function! s:DB_MYSQL_getListColumn(table_name) "{{{
    let result = s:DB_MYSQL_execSql("show columns from ".a:table_name)
    " Strip off header separators ending with a newline
    " let stripped = substitute( result, '+[-]\|+'."[\<C-J>]", '', '' )
    " Strip off column headers ending with a newline
    let stripped = substitute( result, '.\{-}'."[\<C-J>]", '', '' )
    " Strip off preceeding and ending |s
    let stripped = substitute( stripped, '\(\<\w\+\>\).\{-}'."[\<C-J>]", '\1, ', 'g' )
    " Strip off ending comma
    let stripped = substitute( stripped, ',\s*$', '', '' )
    return stripped
endfunction "}}}

function! s:DB_MYSQL_stripHeaderFooter(result) "{{{
    " Strip off header separators ending with a newline
    let stripped = substitute( a:result, '+[-]\|+'."[\<C-V>\<C-J>]", '', '' )
    " Strip off column headers ending with a newline
    let stripped = substitute( stripped, '|.*Tables_in.*'."[\<C-V>\<C-J>]", '', '' )
    " Strip off preceeding and ending |s
    let stripped = substitute( stripped, '|', '', 'g' )
    return stripped
endfunction "}}}

function! s:DB_MYSQL_getDictionaryTable() "{{{
    let result = s:DB_MYSQL_getListTable('')
    return s:DB_MYSQL_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_MYSQL_getDictionaryProcedure() "{{{
    call s:DB_warningMsg( 'Feature not yet available' )
    return '-1'
endfunction "}}}

function! s:DB_MYSQL_getDictionaryView() "{{{
    call s:DB_warningMsg( 'Feature not yet available' )
    return '-1'
endfunction "}}}
"}}}
" ORA exec {{{
function! s:DB_ORA_execSql(str)
    " All defaults are specified in the DB_getDefault function.
    " This contains the defaults settings for all database types
    let output = s:DB_getWType("cmd_header") . a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_getWType("cmd_terminator") . '[^\n\s]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    let tempfile = tempname()
    exe 'redir! > ' . tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))

    let cmd = dbext_bin .  
                \ ' ' . s:DB_getWType("cmd_options") .
                \ s:DB_option(' ', s:DB_get("user"), '') .
                \ s:DB_option('/', s:DB_get("passwd"), '') .
                \ s:DB_option('@', s:DB_get("srvname"), '') .
                \ ' @' . tempfile
    let result = s:DB_runCmd(cmd, output)
    let rc = delete(tempfile)
    if rc != 0
        echo 'Failed to delete: ' . tempfile . ' rc: ' . rc
    endif
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
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-V>\<C-J>]", '', '' )
    " Strip off query statistics
    let stripped = substitute( stripped, '\d\+ rows\_.*', '', '' )
    " Strip off no rows selected
    let stripped = substitute( stripped, 'no rows selected\_.*', '', '' )
    return stripped
endfunction "}}}

function! s:DB_ORA_getDictionaryTable() "{{{
    let result = s:DB_ORA_execSql(
                \ "select table_name     " .
                \ "  from ALL_ALL_TABLES " .
                \ " order by table_name  "
                \ )
    return s:DB_ORA_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_ORA_getDictionaryProcedure() "{{{
    let result = s:DB_ORA_execSql(
                \ "select object_name                          " .
                \ "  from all_objects                          " .
                \ " where object_type IN                       " .
                \ "       ('PROCEDURE', 'PACKAGE', 'FUNCTION') " .
                \ " order by object_name                       "
                \ )
    return s:DB_ORA_stripHeaderFooter(result)
endfunction "}}}

function! s:DB_ORA_getDictionaryView() "{{{
    let result = s:DB_ORA_execSql(
                \ "select view_name    " .
                \ "  from ALL_VIEWS    " .
                \ " order by view_name "
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
    if output !~ s:DB_getWType("cmd_terminator") . '[^\n\s]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    let tempfile = tempname()
    exe 'redir! > ' . tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_fullPath2Bin(s:DB_getWType("bin"))
    let cmd = dbext_bin .  ' ' . 
                \ s:DB_option('', s:DB_getWType("cmd_options"), ' ') .
                \ s:DB_option('-d ', s:DB_get("dbname"), ' ') .
                \ s:DB_option('-U ', s:DB_get("user"), ' ') .
                \ s:DB_option('-h ', s:DB_get("host"), ' ') .
                \ s:DB_option('-p ', s:DB_get("port"), ' ') .
                \ '-q -f ' . tempfile
    let result = s:DB_runCmd(cmd, output)
    let rc = delete(tempfile)
    if rc != 0
        echo 'Failed to delete: ' . tempfile . ' rc: ' . rc
    endif
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
    let query = "select tablename, tableowner " .
                \ " from pg_tables " .
                \ "where tableowner != 'pg_catalog' " .
                \ "  and tablename like '" . a:table_prefix . "%' " .
                \ "order by tablename"
    return s:DB_PGSQL_execSql(query)
endfunction

function! s:DB_PGSQL_getListProcedure(proc_prefix)
    let query = "  SELECT p.proname, pg_get_userbyid(u.usesysid) " .
                \ "  FROM pg_proc p, pg_user u " .
                \ " WHERE p.proowner = u.usesysid " .
                \ "   AND p.proname like '" . a:proc_prefix . "%' " .
                \ " ORDER BY p.proname"
    return s:DB_PGSQL_execSql(query)
endfunction

function! s:DB_PGSQL_getListView(view_prefix)
    let query = "select viewname, viewowner " .
                \ " from pg_views " .
                \ "where viewowner != 'pg_catalog' " .
                \ "  and viewname like '" . a:view_prefix . "%' " .
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
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-V>\<C-J>]", '', '' )
    " Strip off query statistics
    let stripped = substitute( stripped, '(\d\+ rows\_.*', '', '' )
    return stripped
endfunction 

function! s:DB_PGSQL_getDictionaryTable() 
    let result = s:DB_PGSQL_execSql(
                \ "select tablename " .
                \ " from pg_tables " .
                \ "where tableowner != 'pg_catalog' " .
                \ "order by tablename"
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
                \ "select viewname " .
                \ "  from pg_views " .
                \ " where viewowner != 'pg_catalog' " .
                \ " order by viewname"
                \ )
    return s:DB_PGSQL_stripHeaderFooter(result)
endfunction 
"}}}
" SQLSRV exec {{{
function! s:DB_SQLSRV_execSql(str)
    let output = s:DB_getWType("cmd_header") . a:str
    " Only include a command terminator if one has not already
    " been added
    if output !~ s:DB_getWType("cmd_terminator") . '[^\n\s]*$'
        let output = output . s:DB_getWType("cmd_terminator")
    endif

    let tempfile = tempname()
    exe 'redir! > ' . tempfile
    silent echo output
    redir END

    let dbext_bin = s:DB_getWType("bin")
    let cmd = dbext_bin . ' ' . s:DB_getWType("cmd_options")
    let cmd = cmd . ' -U ' .  s:DB_get("user") .
                \ ' -P' . s:DB_get("passwd") .
                \ s:DB_option(' -H ', s:DB_get("host"), ' ') .
                \ s:DB_option(' -S ', s:DB_get("srvname"), ' ') .
                \ s:DB_option(' -d ', s:DB_get("dbname"), ' ') .
                \ ' -i ' . tempfile
    let result = s:DB_runCmd(cmd, output)
    let rc = delete(tempfile)
    if rc != 0
        echo 'Failed to delete: ' . tempfile . ' rc: ' . rc
    endif
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
    let stripped = substitute( a:result, '\_.*-\s*'."[\<C-V>\<C-J>]", '', '' )
    " Strip off query statistics
    let stripped = substitute( stripped, '(\d\+ rows\_.*', '', '' )
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
                \ " from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid ".
                \ "     and o.xtype='U' ".
                \ "     and o.name like '".a:table_prefix."%' ".
                \ " order by o.name")
endfunction

function! s:DB_SQLSRV_getListProcedure(proc_prefix)
    return s:DB_SQLSRV_execSql(
                \ "select convert(varchar,o.name), convert(varchar,u.name) ".
                \ " from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid ".
                \ "     and o.xtype='P' ".
                \ "     and o.name like '".a:proc_prefix."%' ".
                \ " order by o.name")
endfunction

function! s:DB_SQLSRV_getListView(view_prefix)
    return s:DB_SQLSRV_execSql(
                \ "select convert(varchar,o.name), convert(varchar,u.name) ".
                \ " from sysobjects o, sysusers u ".
                \ " where o.uid=u.uid ".
                \ "     and o.xtype='V' ".
                \ "     and o.name like '".a:view_prefix."%' ".
                \ " order by o.name")
endfunction 
function! s:DB_SQLSRV_getDictionaryTable() "{{{
    let result = s:DB_SQLSRV_execSql(
                \ "select convert(varchar,o.name) ".
                \ "  from sysobjects o ".
                \ " where o.xtype='U' ".
                \ " order by o.name"
                \ )
    return s:DB_SQLSRV_stripHeaderFooter(result)
endfunction "}}}
function! s:DB_SQLSRV_getDictionaryProcedure() "{{{
    let result = s:DB_SQLSRV_execSql(
                \ "select convert(varchar,o.name) ".
                \ "  from sysobjects o ".
                \ " where o.xtype='P' ".
                \ " order by o.name"
                \ )
    return s:DB_SQLSRV_stripHeaderFooter(result)
endfunction "}}}
function! s:DB_SQLSRV_getDictionaryView() "{{{
    let result = s:DB_SQLSRV_execSql(
                \ "select convert(varchar,o.name) ".
                \ "  from sysobjects o ".
                \ " where o.xtype='V' ".
                \ " order by o.name"
                \ )
    return s:DB_SQLSRV_stripHeaderFooter(result)
endfunction "}}}
"}}}
" Selector functions {{{
function! s:DB_execSql(query)
    let query = a:query
    if strlen(query) == 0
        call s:DB_warningMsg("No statement to execute!")
        return
    endif

    if s:DB_get("prompt_for_parameters") == "1"
        let query = s:DB_parseQuery(query)
    endif
    
    return s:DB_execFuncTypeWCheck('execSql', query)
endfunction

function! s:DB_execSqlWithDefault(...)
    if (a:0 > 0)
        let sql = a:1
    else
        call s:DB_warningMsg("No statement to execute!")
        return
    endif
    if(a:0 > 1)
        let sql = sql . a:2
    else
        let sql = sql . expand("<cword>")
    endif
    if s:DB_get("prompt_for_parameters") == "1"
        let sql = s:DB_parseQuery(sql)
    endif
    
    return s:DB_execFuncTypeWCheck('execSql', sql)
endfunction

"FIXME: az 'isk' (iskeyword) beállításával nem tudnám rámaccsoltatni a .ot
" tartalmazó (schema alkalmazó) táblanevekre a cwordot?
" I dont know what this says ...
function! s:DB_describeTable(...)
    if(a:0 > 0)
        let table_name = substitute(a:1,'\s*\(\w*\)\s*','\1','')
    else
        let table_name = expand("<cword>")
    endif
    return s:DB_execFuncTypeWCheck('describeTable', table_name)
endfunction

function! s:DB_describeProcedure(...)
    if(a:0 > 0)
        let procedure_name = a:1
    else
        let procedure_name = expand("<cword>")
    endif
    return s:DB_execFuncTypeWCheck('describeProcedure', procedure_name)
endfunction

function! DB_getListColumn(...) 
    if(a:0 > 0) 
        " Strip any leading or trailing spaces
        let table_name = substitute(a:1,'\s*\(\w*\)\s*','\1','')
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
        call s:DB_warningMsg( 'You must supply a table name' )
        return
    endif

    " This will return the result instead of using the result buffer
    let l:prev_use_result_buffer = s:DB_get('use_result_buffer')
    call s:DB_set('use_result_buffer', 0)
    let col_list = s:DB_execFuncTypeWCheck('getListColumn', table_name)
    call s:DB_set('use_result_buffer', l:prev_use_result_buffer)

    if col_list == '-1'
        call s:DB_warningMsg( 'Failed to create column list for ' .
                    \ table_name )
        return ''
    endif

    " Remove all blanks and carriage returns to check for an empty string
    if strlen(substitute( col_list, "[ \<C-J>]*", '', 'g' )) == 0
        if silent_mode == 0
            call s:DB_warningMsg( 'Table not found: ' . table_name )
        endif
        return ''
    endif

    " \<C-J> = Enter
    " Strip off all leading spaces and newlines
    let col_list = substitute( col_list, '^[ '."\<C-J>".']*\ze\w', '', '' )
    " Strip off all following spaces and newlines
    let col_list = substitute( col_list, '\w\>\zs[ '."\<C-J>".']*$', '\1', '' )

    if use_newline_sep == 0
        " Convert newlines into commas
        let col_list = substitute( col_list, '\w\>\zs[ '."\<C-J>".']*\ze\w', '\1, ', 'g' )
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

    " Mark the current line to return to
    let curline     = line(".")
    let curcol      = virtcol(".")

    let sql_commands = '\c\<\(select\|update\|create\|grant' .
                \ '\|delete\|alter\|call\|exec\|insert' .
                \ '\|merge\)\>'
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
        exe 'silent! norm! v/\'.dbext_cmd_terminator."/e\n".'"zy``'
    endif

    " Return to previous location
    exe 'norm! '.curline.'G'.curcol."\<bar>"

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

function! s:DB_getInput(prompt, default_value, cancel_value)
    if v:version >= 602
        return inputdialog( a:prompt, a:default_value, a:cancel_value )
    else
        return inputdialog( a:prompt, a:default_value )
    endif
endfunction

function! DB_getVisualBlock() range
    "FIXME: kitugyamég mithoz az élet: Made this a public function to be used in the vmapping
    let save = @"
    silent normal gvy
    let vis_cmd = @"
    let @" = save
    return vis_cmd
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
        return
    endif

    let l:prev_use_result_buffer = s:DB_get('use_result_buffer')
    call s:DB_set('use_result_buffer', 0)
    " let dict_list = s:DB_{b:dbext_type}_getDictionary{a:which}()
    let dict_list = s:DB_execFuncTypeWCheck('getDictionary'.a:which)
    call s:DB_set('use_result_buffer', l:prev_use_result_buffer)

    if dict_list != '-1'
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
        " |\n\s*\n\@='     - Any middle of ending blank lines
        " Thanks to Suresh Govindachari and Klaus Bosau
        let dict_list = substitute(dict_list, 
                    \ '^\(\s*\n\)*\|\n\s*\n\@=', 
                    \ '', 'g')
        " Remove trailing blanks on each name
        let dict_list = substitute(dict_list, 
                    \ '\s*\n', '\n', 'g')
        
        " Create a new temporary file with the table names
        " let b:dbext_dict_{a:which}_file = tempname()
        let temp_file = tempname()
        call s:DB_set("dict_".which_dict."_file", temp_file )
        exe 'redir! > ' . temp_file
        silent echo dict_list
        redir END
        
        " Add the new temporary file to the dictionary setting for this buffer
        silent! exec 'setlocal dictionary+='.temp_file
        echo a:which . ' dictionary created'
        call s:DB_addBufDictList( bufnr("%") )

        return temp_file
    else
        call s:DB_warningMsg( 'Failed to create ' . which_dict . ' dictionary' )
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
            call s:DB_warningMsg( 'Failed to delete ' . which_dict . ' dictionary: ' . 
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
            return
        endif
    endif

    return s:DB_get("dict_".which_dict."_file")
endfunction "}}}
"}}}
" Autocommand Functions {{{
function! s:DB_auVimLeavePre() "{{{
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
" runCmd {{{
function! s:DB_runCmd(cmd, sql)
    " Store current window number so we can return to it
    let cur_winnr = winnr()
    let res_buf_name = s:DB_resBufName()
    " Retieve this value before we switch buffers
    let l:display_cmd_line = s:DB_get('display_cmd_line') 
    let l:buffer_lines = s:DB_get('buffer_lines')

    " Do not use bufexists(res_buf_name), since it uses a fully qualified
    " path name to search for the buffer, which in effect opens multiple
    " buffers called "Result" if the files that you are executing the
    " commands from are in different directories.
    let buf_exists = bufexists(bufnr(res_buf_name))
    let res_buf_nbr = bufnr(res_buf_name)

    if s:DB_get('use_result_buffer') == 1
        if buf_exists == 0
            " Create the new buffer
            silent exec 'belowright ' . l:buffer_lines . 'new ' . res_buf_name
        else
            if bufwinnr(res_buf_nbr) == -1
                " if the buffer is not visible, wipe it out and recreate it,
                " this will position us in the new buffer
                exec 'bwipeout! ' . res_buf_nbr
                silent exec 'bot ' . l:buffer_lines . 'new ' . res_buf_name
            else
                " If the buffer is visible, switch to it
                exec bufwinnr(res_buf_nbr) . "wincmd w"
            endif
        endif
        setlocal modified
        " Create a buffer mapping to clo this window
        nnoremap <buffer> q :clo<cr>
        " Delete all the lines prior to this run
        %d
        " If the user wants to see the command line, echo it
        " as the first line in the output
        if l:display_cmd_line == 1
            put = 'Last command:'
            put = a:cmd
            put = 'Last SQL:'
            put = a:sql
        endif
        " Run the command and read it into the Result buffer
        " silent exec "read !" . a:cmd . " 2>&1"
        " Decho a:cmd
        " echom a:cmd
        exec 'silent! normal! G'
        silent exec "read !" . a:cmd

        " If there was an error, show the command just executed
        " for debugging purposes
        if v:shell_error
            exec 'silent! normal! G'
            put = 'To change connection parameters:'
            put = ':DBPromptForParameters'
            put = 'Or'
            put = ':DBSetOption user\|passwd\|dsnname\|srvname\|dbname\|host\|port\|... <value>'
            put = ':DBSetOption passwd new_password'
            put = 'Last command:'
            put = a:cmd
            put = 'Last SQL:'
            put = a:sql
        endif
        " Since this is a small window, remove any blanks lines
        silent %g/^\s*$/d
        " Fix the ^M characters, if any
        silent execute "%s/\<C-M>\\+$//e"
        " Dont allow modifications, and do not wrap the text, since
        " the data may be lined up for columns
        setlocal nomodified
        setlocal nowrap
        " Go to top of output
        norm gg
        " Return to original window
        " exe "norm \<c-w>p\<c-w>l"
        exec cur_winnr."wincmd w"
    else " Don't use result buffer
        if l:display_cmd_line == 1
            echo 'Last command:'
            echo a:cmd
            echo 'Last SQL:'
            echo a:sql
        endif
        let result = system(a:cmd)
        " If there was an error, return -1
        " in this mode do not show the actual message
        if v:shell_error
            let result = '-1'
        endif
        return result
    endif
    return
endfunction "}}}
" Parsers {{{
function! s:DB_parseQuery(query)
    if &filetype == "sql"
        " Dont parse the SQL query, since DB_parseHostVariables
        " will pickup the standard host variables for prompting.
        " let query = s:DB_parseSQL(a:query)
        return s:DB_parseHostVariables(a:query)
    elseif &filetype == "java" || 
                \ &filetype == "jsp"  || 
                \ &filetype == "javascript" 
        let query = s:DB_parseJava(a:query)
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
            let response = 3
        elseif var_val == "" 
            " If empty, check if they want to leave it empty
            " of skip this variable
            let response = confirm("Your value is empty!",
                                    \ "&Skip\n&Use blank\n&Stop Prompting")
        endif
        if response == 1
            " Skip this match and move on to the next
            let index = match(str, a:exp_find_str, index+strlen(var))
        elseif response == 2
            " Replace the variable with what was entered
            let replace_sub = '\%'.index.'c'.'.\{'.strlen(var).'}'
            let str = substitute(str, replace_sub, var_val, '')
            let index = match(str, a:exp_find_str, index+strlen(var_val))
        else
            " Skip all remaining matches
            break
        endif
    endwhile
    return str
endfunction 
"}}}

" Host Variable Parser {{{
function! s:DB_parseHostVariables(query)
    let query = a:query
    " If query is a SELECT statement, remove any INTO clauses
    " Use an case insensitive comparison
    " For some reason [\n\s]* does not work
    if query =~? '^[\n \t]*select'
        let query = substitute(query, '\cINTO.*FROM', 'FROM', 'g')
    endif

    " Must default the statements to parse
    let dbext_parse_statements = s:DB_get("parse_statements")
    " Verify the string is in the correct format
    " Strip off any trailing commas
    let dbext_parse_statements =
                \ substitute(dbext_parse_statements, ',$','','')
    " Convert commas to regex ors
    let dbext_parse_statements =
                \ substitute(dbext_parse_statements, ',', '\\|', 'g')

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
                let response = confirm("Do you want to prompt for input variables?"
                            \, "&Yes\n&No", 1 )
                " echom "\nresponse: ".response."\n"
            endif
        endif
        " If the user does not want to parse the query
        " return the query as is
        if response == 2
            return query
        endif
        " Process each variable definition, format is as follows:
        " identifier1[wW][qQ];identifier2[wW][qQ];identifier3[wW][qQ];
        let pos = 0
        call MvIterCreate(s:DB_get("variable_def"), ',', "MvIdentifiers")
        while MvIterHasNext('MvIdentifiers')
            let variable_def = MvIterNext('MvIdentifiers')
            " Extract the identifier, use the greed nature of regex.
            " Allow them to specify more than a single character for the
            " search. We must assume they follow the correct format
            " though and the criteria ends with a WQ; (case insensitive)
            let identifier = substitute(variable_def,'\(.*\)[wW][qQ]$','\1','')
            let following_word_option = 
                        \ substitute(variable_def, '.*\([wW]\)[qQ]$', '\1', '')
            let quotes_option = 
                        \ substitute(variable_def, '.*\([qQ]\)$', '\1', '')

            " Validation checks
            if strlen(identifier) != 0
                " Make sure no word characters preceed the identifier
                let no_preceed_word = '\(\w\)\@<!'
            else
                let msg = "dbext: Variable Def: Invalid identifier[" .
                            \ variable_def . "]"
                call s:DB_warning_msg(msg)
                return query
            endif
            " w - MUST have word characters after it
            " W - CANNOT have any word characters after it
            if following_word_option ==# 'w'
                let following_word = '\w\+'
                let retrieve_ident = identifier . following_word
            elseif following_word_option ==# 'W'
                let following_word = '\(\w\)\@<!'
                let retrieve_ident = identifier
            else
                let msg = "dbext: Variable Def: " .
                            \ "Invalid following word indicator[" .
                            \ variable_def . "]"
                call s:DB_warning_msg(msg)
                return query
            endif
            " q - quotes do not matter
            " Q - CANNOT be surrounded in quotes
            if quotes_option ==# 'q'
                let quotes = ''
            elseif quotes_option ==# 'Q'
                let quotes = "'".'\@<!'
            else
                let msg = "dbext: Variable Def: Invalid quotes indicator[" .
                            \ variable_def . "]"
                call s:DB_warning_msg(msg)
                return query
            endif


            " If W is chosen, then the identifier cannot be followed
            " by any word characters.  If this is the case (like with ?s)
            " there is no way to distinguish between which ? you are 
            " prompting for, therefore count the identifier and
            " display this information while prompting.
            if variable_def =~# 'W[qQ]$'
                let count_matches = 1
            else
                let count_matches = 0
            endif

            let srch_cond = quotes . no_preceed_word .
                        \ identifier . following_word . quotes
            let query = s:DB_searchReplace(query, srch_cond,
                        \ retrieve_ident, count_matches)
        endwhile
        call MvIterDestroy("MvIdentifiers")
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

    " Prompt for the variables which are part of
    " string concentations like this:
    "   "SELECT * FROM ".$prefix."product"
    let var_expr = '"\s*\.\s*\(\$.\{-}\)\.\s*"'
    "  "\s*         - Double quote followed any space 
    "  \.\s*        - A period and any space
    "  \(\$.\{-}\)  - The variable / obj / method
    "  \.\s*"       - A period followed by any space followed by a double quote
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
    let query = substitute(query, 
                \ '\s*"\s*+\s*"\s*', 
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
    "    "select " .
    "    \ " * from "
    "    \ . " some_table ";
    let query = substitute(query, 
                \ '\s*"\s*\\\?\s*\.\s*\\\?\s*"\s*', 
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

    " Reset previous multval profile variables
    let l:profile_params_mv = ''
    let l:profile_values_mv = ''

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
"}}}
" Commands "{{{
command! -nargs=+ DBExecSQL    :call s:DB_execSql(<q-args>)
command! -nargs=+ Call         :call s:DB_execSql("call " . <q-args>)
command! -nargs=+ Select       :call s:DB_execSql("select " . <q-args>)
command! -nargs=+ Update       :echo s:DB_execSql("update " . <q-args>)
command! -nargs=+ Insert       :echo s:DB_execSql("insert " . <q-args>)
command! -nargs=+ Delete       :echo s:DB_execSql("delete " . <q-args>)
command! -nargs=+ Drop         :echo s:DB_execSql("drop " . <q-args>)
command! -nargs=+ Alter        :echo s:DB_execSql("alter " . <q-args>)
command! -nargs=+ Create       :echo s:DB_execSql("create " . <q-args>)
command! -nargs=1 DBSetOption  :call s:DB_setMultipleOptions(<q-args>)
command! -nargs=1 DBGetOption  :echo s:DB_get(<q-args>)
command! -nargs=0 DBLeave      :echo s:DB_auVimLeavePre()
"}}}
call s:DB_buildLists()
call s:DB_resetGlobalParameters()
augroup dbext
    au!
    autocmd BufReadPost * if &modeline == 1 | call s:DB_checkModeline() | endif
    autocmd BufDelete   * call s:DB_auBufDelete( bufnr(expand("<afile>")) )
    autocmd VimLeavePre * call s:DB_auVimLeavePre()
augroup END
" vim:fdm=marker:nowrap:ts=4:expandtab:
