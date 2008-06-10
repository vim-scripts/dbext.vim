" File:          dbext_dbi.vim
" Copyright (C) 2002-7, Peter Bagyinszki, David Fishburn
" Purpose:       A perl extension for use with dbext.vim. 
"                It adds transaction support and the ability
"                to reach any database currently supported
"                by Perl and DBI.
" Version:       6.10
" Maintainer:    David Fishburn <fishburn@ianywhere.com>
" Authors:       David Fishburn <fishburn@ianywhere.com>
" Last Modified: Wed 28 May 2008 10:43:28 PM Eastern Daylight Time
" Created:       2007-05-24
" Homepage:      http://vim.sourceforge.net/script.php?script_id=356
"
" Help:         :h dbext.txt 
"
" System Requirements:
"   
"    VIM with embedded perl support.  You can check if your Vim has this
"    support using
"    :echo has('perl')
"
"    This plugin supports these perl modules:  
"        DBI
"        DBD::ODBC
"
"    Install these perl modules, using ActiveState Perl on
"    Windows you can do it as follows:
"        cd Perl_Root_dir\bin
"        ppm.bat
"            install DBI
"            install DBD::ODBC
"            quit
"
"    Installing the SQL Anywhere DBI module (ensure you are using 10.0.1.3525
"    and above)
"        cd %SQLANY10%\src\perl
"        copy "%SQLANYSAMP10%\demo.db"
"        dbeng10 demo
"
"        Make sure SQLANY10 is in your path before any other versions of SQL
"        Anywhere.
"        "C:\Program Files\Microsoft Visual Studio .Net 2003\Common7\Tools\vsvars32.bat"
"        or
"        "C:\Program Files\Microsoft Visual Studio 8\Common7\Tools\vsvars32.bat"
"            perl Makefile.PL
"            nmake
"            nmake test
"            nmake install
"
"    Installing the Oracle DBI module
"        cd Perl_Root_dir\bin
"        ppm-shell.bat
"            install DBD::Oracle
"            quit
"
"    Installing the Sybase (ASE) DBI module
"        "C:\Program Files\Microsoft Visual Studio 8\Common7\Tools\vsvars32.bat"
"        cd Perl_Root_dir\bin
"        perl -MCPAN -e shell
"            install DBD::Sybase
"            quit
"
"    Installing the DB2 DBI module
"        Make sure your DB2_HOME directory has been set
"        cd Perl_Root_dir\bin
"        perl -MCPAN -e shell
"            install DBD::DB2
"            quit
"
"    Installing the binary MySQL DBI module
"        cd Perl_Root_dir\bin
"        ppm-shell.bat
"            install DBD-mysql
"            quit
"
"    Installing the Sybase ASE or SQL Server DBI module
"        http://lists.ibiblio.org/pipermail/freetds/2001q3/004748.html
"        cd Perl_Root_dir\bin
"        ppm-shell.bat
"            install Sybase-TdsServer
" Testing:
"     http://www.easysoft.com/developer/languages/perl/sql_server_unix_tutorial.html
"       perl -MCPAN -e shell
"       perl -e "use DBD::ODBC;"
"       perl -MDBD::ODBC -e "print $DBD::ODBC::VERSION;"
"       perl -MDBI -e "DBI->installed_versions;"
"
" Usage:  
"    dbext_dbi.vim is designed to be used by the dbext.vim plugin.
"    See :h dbext.txt
"
" Debugging Perl DBI:
"     http://www.easysoft.com/developer/languages/perl/dbi-debugging.html
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

if exists("g:loaded_dbext_dbi") 
   finish
endif
if !has('perl')  
    let g:loaded_dbext_dbi = -1
    let g:loaded_dbext_dbi_msg = 'Vim does not have perl support enabled'
    finish
endif
let g:loaded_dbext_dbi = 610

if !exists("dbext_dbi_debug")
   let g:dbext_dbi_debug = 0
endif
if !exists("dbext_dbi_result")
   let g:dbext_dbi_result = -1
endif
if !exists("dbext_dbi_msg")
   let g:dbext_dbi_msg = ""
endif
if !exists("dbext_dbi_sql")
   let g:dbext_dbi_sql = ""
endif
if !exists("dbext_dbi_max_rows")
   let g:dbext_dbi_max_rows = 300
endif
if !exists("dbext_default_dbi_column_delimiter")
   let g:dbext_default_dbi_column_delimiter = "  "
endif
if !exists("dbext_dbi_trace_level")
   let g:dbext_dbi_trace_level = 0
endif

" See help use-cpo-save for info on the variable save_cpo  
let s:save_cpo = &cpo
set cpo&vim

function! dbext_dbi#DBI_load_perl_subs()

    if exists("g:dbext_dbi_loaded_perl_subs") 
       finish
    endif

    " echomsg "Loading Perl subroutines"

    let g:loaded_dbext_dbi_msg = 'pre test of perl version'
    perl << EOVersionTest
       require 5.8.0;
       VIM::DoCommand('let g:loaded_dbext_dbi_msg=\'passed test of perl version\'');
EOVersionTest

    if (g:loaded_dbext_dbi_msg != 'passed test of perl version')
       let g:loaded_dbext_dbi_msg = 'failed test of perl version'
       return
    endif

    let g:loaded_dbext_dbi_msg = 'creating Perl subroutines'
    perl << EOCore

VIM::DoCommand('let g:loaded_dbext_dbi_msg=\'after EOCore\'');
BEGIN {(*STDERR = *STDOUT) || die;} 

use diagnostics;
use warnings;
use strict;
use Data::Dumper qw( Dumper );
use DBI;

VIM::DoCommand('let g:loaded_dbext_dbi_msg=\'after warnings\'');
my $conn;
my %connections;
my @result_headers;
my @result_set;
my @result_col_length;
my $result_max_col_width;
my $result_msg    = "";
my $max_rows      = 300;
my $min_col_width = 4;   # First NULL
my $test_inc      = 0;
my $conn_inc      = 0;
my $dbext_dbi_sql = "";
my $col_sep_vert  = "  ";
my $debug         = db_is_debug();


VIM::DoCommand('let g:loaded_dbext_dbi_msg=\'db_set_vim_var\'');
sub db_set_vim_var
{
    my $var_name = shift;
    my $string   = shift;
    VIM::DoCommand('let g:loaded_dbext_dbi_'.$var_name.'='.$string);
}


# db_set_vim_var('msg', 'one');
# db_set_vim_var('msg', "two");
# db_set_vim_var('msg', "'three'");
# db_set_vim_var('msg', '"four"');
db_set_vim_var('msg', '"db_trim_white_space"');
sub db_trim_white_space($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}


db_set_vim_var('msg', '"db_echo"');
sub db_echo 
{
    my $msg = shift;

    VIM::Msg('DBI:'.$msg, 'WarningMsg');
    # VIM::DoCommand('echohl WarningMsg'); 
    # VIM::DoCommand("echomsg 'DBI:$msg'");
    # VIM::DoCommand('echohl None');
    return 0;
}

db_set_vim_var('msg', '"db_debug"');
sub db_debug 
{
    my $msg = shift;
    $debug and db_echo($msg);
}

db_set_vim_var('msg', '"db_is_debug"');
sub db_is_debug 
{
    return db_vim_eval('g:dbext_dbi_debug');
}

db_set_vim_var('msg', '"db_vim_eval"');
sub db_vim_eval 
{
    my $cmd = shift;

    if( defined($cmd) ) {
        return VIM::Eval($cmd);
    }
    return "";
}

db_set_vim_var('msg', '"db_vim_print"');
sub db_vim_print 
{
    my $line_nbr      = shift;
    my $line_txt      = shift;
    my $printed_lines = 0;
    my $max_col_width = $result_max_col_width + 2;

    if ( ! defined($line_nbr) ) {
        db_echo('db_vim_print invalid line number');
        return -1;
    }

    if ( ! defined($line_txt) ) {
        $line_txt = "";
    }

    my @lines = split("\n", $line_txt);

    foreach my $line (@lines) {
        if ( $printed_lines > 0 ) {
            # Multiple lines will only be within the string if the
            # user is printing in a vertical orientation.
            # Therefore if the printed_lines is > 1 we know
            # we have split the column data and we need to prepend
            # blanks to line up the text with the data above.
            $line = (' ' x $max_col_width).$line;
        }
        $main::curbuf->Append($line_nbr, $line);
        $line_nbr++;
        $printed_lines++;
    }
    return $printed_lines;
}

db_set_vim_var('msg', '"db_get_defaults"');
sub db_get_defaults 
{
    $col_sep_vert = db_vim_eval('g:dbext_default_dbi_column_delimiter');
}

db_set_vim_var('msg', '"db_escape"');
sub db_escape 
{
    my $escaped = shift;
    if( defined($escaped) ) {
        $escaped =~ s/"/\\"/g;
        $escaped =~ s/\\/\\\\/g;
    }

    return $escaped;
}

db_set_vim_var('msg', '"db_remove_newlines"');
sub db_remove_newlines 
{
    my $escaped = shift;
    $escaped =~ s/\n/ /g;

    return $escaped;
}

db_set_vim_var('msg', '"db_get_available_drivers"');
sub db_get_available_drivers 
{
    my @ary = DBI->available_drivers;
    db_echo('db_available_drivers:'.Dumper(@ary));
    return 0;
}

db_set_vim_var('msg', '"db_list_connections"');
sub db_list_connections
{
    db_debug('db_list_connections:'.Dumper(%connections));
    my @row;
    my @table;
    my @col_length;
    my $max_col_width = 0;
    my $i = 0;
    my @headers = [ ("Buffer", "Driver", "AutoCommit", "CommitOnDisconnect", "Connection Parameters") ];
    
    foreach my $row2 ( @headers ) {
        db_debug('db_list_connections:R'.Dumper($row2));
        foreach my $col2 ( @{$row2} ) {
            my $temp_length = length((defined($col2)?$col2:""));
            if ( !defined($col_length[$i]) ) {
                $col_length[$i] = 0;
            }
            $col_length[$i] = ( $temp_length > $col_length[$i] ? $temp_length : $col_length[$i] );
            db_debug("db_list_connections:i:$i:L:".$col_length[$i]);
            $max_col_width = ( $temp_length > $max_col_width ? $temp_length : $max_col_width );
            $i++;
        }
    }

    if ( keys(%connections) > 0 )
    {
        foreach my $bufnr ( keys %connections ) {
            @row = ($bufnr
                    , $connections{$bufnr}->{'driver'}
                    , $connections{$bufnr}->{'AutoCommit'}
                    , $connections{$bufnr}->{'CommitOnDisconnect'}
                    , $connections{$bufnr}->{'params'}
                    );
            push @table, [ @row ]; 
            $i = 0;
            foreach my $col ( @row ) {
                my $temp_length = length((defined($col)?$col:""));
                $col_length[$i] = ( $temp_length > $col_length[$i] ? $temp_length : $col_length[$i] );
                $i++;
            }
        }
    }
    @result_headers       = @headers;
    @result_set           = @table;
    @result_col_length    = @col_length;
    $result_max_col_width = $max_col_width;

    db_debug('db_list_connections:pre-formatting'.Dumper(@result_set));
    db_format_array();

    if ( keys(%connections) == 0 )
    {
        push @result_set, [ ("There are no active DBI connections", "", "", "", "") ];
    } 
    db_debug('db_list_connections:final:'.Dumper(@result_set));
    # TODO 
    # This should define an array so db_print_results can be used
    VIM::DoCommand("let g:dbext_dbi_result='DBI:'");
    VIM::DoCommand("let g:dbext_dbi_msg=''");
    return 0;
}

db_set_vim_var('msg', '"db_get_info"');
sub db_get_info
{
    my $option = shift;

    my $conn_local;
    if ( ! db_is_connected() ) {
        db_echo("db_get_info:You must connect first");
        return -1;
    }

    $conn_local = db_get_connection();

    my $result = "";

    if ( defined($option) ) {
        $result = $conn_local->get_info($option);
    } else {
        $result = "DBMS Name[".$conn_local->get_info(17).
                "] Version[".$conn_local->get_info(18)."]";
    }

    db_debug('db_get_info:'.$result);
    VIM::DoCommand("let g:dbext_dbi_result='".$result."'");
    return 0;
}

db_set_vim_var('msg', '"db_commit"');
sub db_commit 
{
    my $conn_local;
    db_debug("Committing connection");
    if ( ! db_is_connected() ) {
        VIM::DoCommand("let g:dbext_dbi_result=-1");
        VIM::DoCommand("let g:dbext_dbi_msg='You are not connected to a database'");
        return -1;
    }

    $conn_local = db_get_connection();

    my $rc = $conn_local->commit;
    VIM::DoCommand("let g:dbext_dbi_result='".$rc."'");
    return $rc;
}

db_set_vim_var('msg', '"db_rollback"');
sub db_rollback 
{
    my $conn_local;
    
    db_debug("Rolling back connection");
    if ( ! db_is_connected() ) {
        VIM::DoCommand("let g:dbext_dbi_result=-1");
        VIM::DoCommand("let g:dbext_dbi_msg='You are not connected to a database'");
        return -1;
    }

    $conn_local = db_get_connection();
        
    my $rc = $conn_local->rollback;
    VIM::DoCommand("let g:dbext_dbi_result='".$rc."'");
    return $rc;
}

db_set_vim_var('msg', '"db_is_connected"');
sub db_is_connected 
{
    my $bufnr        = shift;
    my $is_connected = 0;
    my $conn_local;
    $test_inc++;
    db_debug('db_is_connected:test_inc:'.$test_inc);
    
    if( ! defined($bufnr) ) {
        db_debug('db_is_connected:looking up $bufnr');
        $bufnr        = db_vim_eval("bufnr('%')");
    }
    if( %connections ) {
        if( ! exists($connections{$bufnr}) ) {
            db_debug('db_is_connected:hash does not exist:'.$bufnr);
        } else {
            db_debug('db_is_connected:hash exists:'.$bufnr);
            $conn_local = $connections{$bufnr}->{'conn'};
        }
    }
    if( defined($conn_local) ) {
        db_debug('db_is_connected:conn exists');
        if( $conn_local->{Active} ) {
            db_debug('db_is_connected:seems active');
            $is_connected = 1;
        } else {
            db_debug('db_is_connected:disconnected');
        }
    } else {
        db_debug('db_is_connected:NO conn');
    }
    VIM::DoCommand("let g:dbext_dbi_result='".$is_connected."'");
    return $is_connected;
}

db_set_vim_var('msg', '"db_get_connection"');
sub db_get_connection 
{
    my $bufnr        = shift;
    my $conn_local;
    
    if( ! defined($bufnr) ) {
        db_debug('db_get_connection:looking up $bufnr');
        $bufnr        = db_vim_eval("bufnr('%')");
    }
    if ( ! db_is_connected($bufnr) ) {
        db_debug('db_get_connection:connection not found:'.$bufnr);
        return undef;
    }

    db_debug('db_get_connection:returning:'.$bufnr);
    $conn_local = $connections{$bufnr}->{'conn'};
    return $conn_local;
}

db_set_vim_var('msg', '"db_connect"');
sub db_connect 
{
    my $driver     = shift;
    my $conn_parms = shift;
    my $uid        = shift;
    my $pwd        = shift;
    my $bufnr      = db_vim_eval("bufnr('%')");
    my $conn_local;

    # $debug         = db_is_debug();
    # db_debug("Connect: driver:$driver parms:$conn_parms U:$uid P:$pwd");

    db_debug('db_connected:checking for existing connection');
    if ( db_is_connected() ) {
        return 0;
    }

    if ( ! defined($driver) ) {
        # db_echo("Invalid driver:$driver");
        VIM::DoCommand("let g:dbext_dbi_msg='Invalid driver:".$driver."'");
        VIM::DoCommand("let g:dbext_dbi_result=-1");
        return -1;
    }
    if ( ! defined($uid) ) {
        # db_echo("Invalid userid:$uid");
        VIM::DoCommand("let g:dbext_dbi_msg='Invalid userid:".$uid."'");
        VIM::DoCommand("let g:dbext_dbi_result=-1");
        return -1;
    }
    if ( ! defined($pwd) ) {
        # db_echo("Invalid password:$pwd");
        VIM::DoCommand("let g:dbext_dbi_msg='Invalid password:".$pwd."'");
        VIM::DoCommand("let g:dbext_dbi_result=-1");
        return -1;
    }

    my $DATA_SOURCE = "DBI:$driver:$conn_parms";

    VIM::DoCommand("let g:dbext_dbi_msg='".$DATA_SOURCE."'");
    db_debug('db_connected:connecting to:'.$DATA_SOURCE);
    # Use global connection object
    eval {
        # LongReadLen sets the maximum size of a BLOB that 
        # can be retrieved from the database.
        # This value can be overriden from your connection string
        # or by using:
        #     DBSetOption driver_parms=LongReadLen=4096
        #
        # LongTruncOk indicates to allow data truncation,
        # and do not report an error.
        $conn_local = DBI->connect( $DATA_SOURCE, $uid, $pwd,
                    { AutoCommit => 1, 
                    LongReadLen => 500, 
                    LongTruncOk => 1, 
                    RaiseError => 0, 
                    PrintError => 0, 
                    PrintWarn => 0 } 
                    );
        # or die $DBI::errstr;
    };

    if ($@) {
        VIM::DoCommand('let g:dbext_dbi_msg="Cannot connect to data source:\\n'.$DATA_SOURCE." using:".$uid."\n".$@.'"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }
    if ( ! $DBI::errstr eq "" ) {
        VIM::DoCommand('let g:dbext_dbi_msg="Cannot connect to data source:\\n'.$DATA_SOURCE." using:".$uid." SQLCode:".$DBI::err."\n".db_escape($DBI::errstr).'"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }

    $connections{$bufnr} = {'conn'               => $conn_local
                           ,'driver'             => $driver
                           ,'uid'                => $uid
                           ,'params'             => $conn_parms
                           ,'AutoCommit'         => 1
                           ,'CommitOnDisconnect' => 1
                           };
    db_debug('db_connected:checking if successful');
    if ( ! db_is_connected() ) {
        # db_debug("conn:3");
        # db_echo("Cannot connect to data source:$DATA_SOURCE:$DBI::errstr");
        # db_debug("conn:4");
        VIM::DoCommand('let g:dbext_dbi_msg="Cannot connect to data source:\\n'.$DATA_SOURCE." using:".$uid." SQLCode:".$DBI::err."\n".db_escape($DBI::errstr).'"');
        VIM::DoCommand("let g:dbext_dbi_result=-1");
        return -1;
    }

    my $trace_level = db_vim_eval("g:dbext_dbi_trace_level");
    if ( ! $trace_level eq "0" ) {
        my $vim_dir = db_vim_eval("expand('".'$VIM'."')");
        $conn_local->trace($trace_level, $vim_dir.'\dbi_trace.txt');
    }
    return 0;
}

db_set_vim_var('msg', '"db_disconnect"');
sub db_disconnect
{
    my $bufnr        = shift;
    my $conn_local;

    VIM::DoCommand("let g:dbext_dbi_result='-1'");

    if( ! defined($bufnr) ) {
        db_debug('db_disconnect:looking up $bufnr');
        $bufnr        = db_vim_eval("bufnr('%')");
    }
    db_debug('db_disconnect:checking for existing connection:'.$bufnr);
    if ( ! db_is_connected($bufnr) ) {
        return 0;
    }

    $conn_local = db_get_connection($bufnr);

    if( ! defined($conn_local) ) {
        db_debug('db_disconnect:This should not have happened since this buffer was connected:'.$bufnr);
        return -1;
    }

    db_debug("db_disconnect:B:$bufnr A:".$conn_local->{AutoCommit}." C:".$connections{$bufnr}->{'CommitOnDisconnect'});
    if( $conn_local->{AutoCommit} == 0 && $connections{$bufnr}->{'CommitOnDisconnect'} == 1 ) {
        db_debug('db_disconnected: forcing COMMIT');
        $conn_local->commit;
    }

    db_debug('db_disconnect:disconnecting');
    my $rc = $conn_local->disconnect();

    # Remove the connection from the hash
    db_debug('db_disconnect:Removing connection for buffer from hash:'.$bufnr);
    delete $connections{$bufnr};
    db_debug('db_disconnect:'.Dumper(%connections));

    VIM::DoCommand("let g:dbext_dbi_result='1'");
    return 0;
}

db_set_vim_var('msg', '"db_disconnect_all"');
sub db_disconnect_all
{
    my $conn_local;
    my $rc;
    
    db_debug('db_disconnect_all:Iterating through all open connections');
    if ( keys(%connections) > 0 )
    {
        foreach my $bufnr ( keys %connections ) {
            db_debug('db_disconnecting buffer:'.$bufnr);
            db_disconnect($bufnr);
        }
    }
    return 0;
}


db_set_vim_var('msg', '"db_get_connection_option"');
sub db_get_connection_option
{
    my $option = shift;
    my $conn_local;

    $debug         = db_is_debug();
    if ( ! defined($option) ) {
        db_debug("An option and value must be specified");
        VIM::DoCommand('let g:dbext_dbi_msg="An option must be specified"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }

    if ( ! db_is_connected() ) {
        db_debug("You are not connected to a database");
        VIM::DoCommand('let g:dbext_dbi_msg="You are not connected to a database"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }

    $conn_local = db_get_connection();
    if ( ! defined($conn_local->{$option}) ) {
        db_debug("Option[$option] does not exist");
        VIM::DoCommand('let g:dbext_dbi_msg="Option['.$option.'] does not exist"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }

    # Use global connection object
    # This expecting a boolean value (ie AutoCommit)
    VIM::DoCommand('let g:dbext_dbi_msg=""');
    VIM::DoCommand('let g:dbext_dbi_result="'.$conn_local->{$option}.'"');
    #    or die $DBI::errstr;
    return 0;
}

db_set_vim_var('msg', '"db_set_connection_option"');
sub db_set_connection_option
{
    my $option = shift;
    my $value  = shift;
    my $bufnr  = db_vim_eval("bufnr('%')");
    my $conn_local;

    $debug         = db_is_debug();
    if ( ! defined($option) || ! defined($value) ) {
        db_debug("Option and value must be specified");
        VIM::DoCommand('let g:dbext_dbi_msg="Option and value must be specified"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }

    if ( ! db_is_connected() ) {
        db_debug("You are not connected to a database");
        VIM::DoCommand('let g:dbext_dbi_msg="You are not connected to a database"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }

    $conn_local = db_get_connection();
    # if ( ! defined($conn_local->{$option}) ) {
    #     db_debug("Option[$option] does not exist");
    #     VIM::DoCommand('let g:dbext_dbi_msg="Option['.$option.'] does not exist"');
    #     VIM::DoCommand('let g:dbext_dbi_result="-1"');
    #     return -1;
    # }

    # Use global connection object
    # This expecting a boolean value (ie AutoCommit)
    $conn_local->{$option} = $value;
    #    or die $DBI::errstr;

    my $last_error_msg = '';
    if ( defined($DBI::errstr) ) {
        $last_error_msg = "Failed to set option[".$option."] Code[".$DBI::err."]  Error[".$DBI::errstr."]";
        db_debug("db_set_connection_option:$last_error_msg");
        VIM::DoCommand('let g:dbext_dbi_msg="'.$last_error_msg.'"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }
    db_debug("ConnOpt: $option set to:".$conn_local->{$option}.$last_error_msg);

    if ( $option eq 'AutoCommit' ) {
        $connections{$bufnr}->{AutoCommit} = $value;
    }

    if ( $option eq 'DBI_commit_on_disconnect' ) {
        $connections{$bufnr}->{'CommitOnDisconnect'} = $value;
    }

    VIM::DoCommand('let g:dbext_dbi_msg=""');
    VIM::DoCommand('let g:dbext_dbi_result="1"');
    return 0;
}

db_set_vim_var('msg', '"db_query"');
sub db_query 
{
    my $sql = shift;
    my $conn_local;
    if ( ! defined($sql) ) {
        $sql = '';
    }

    $debug         = db_is_debug();
    db_debug("db_query:SQL:".$sql);
    if ( length($sql) == 0 ) {
        $sql       = db_vim_eval('g:dbext_dbi_sql');
        db_debug("db_query:SQL after eval:".$sql);
    }
    if ( length($sql) == 0 ) {
        VIM::DoCommand("let g:dbext_dbi_result=-1");
        VIM::DoCommand("let g:dbext_dbi_msg='No statement to exeucte'");
        return -1;
    }
    if ( ! db_is_connected() ) {
        db_debug("db_query:You must connect first");
        VIM::DoCommand("let g:dbext_dbi_result=-1");
        VIM::DoCommand("let g:dbext_dbi_msg='You must connect first'");
        return -1;
    }
 
    $conn_local = db_get_connection();
    my $sth = undef;
    my $sel = $sql;
    $sth = $conn_local->prepare( $sel );
    db_debug("db_query:prepared:".$sql);
    if ( ! $DBI::errstr eq "" ) {
        $result_msg='SQLCode:'.$DBI::err.' Msg:'.db_escape($DBI::errstr);
        VIM::DoCommand('let g:dbext_dbi_msg="'.$result_msg.'"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }

    $sth->execute;
    db_debug("db_query:executed:".$sql);
    if ( ! $DBI::errstr eq "" ) {
        $result_msg='SQLCode:'.$DBI::err.' Msg:'.db_escape($DBI::errstr);
        db_debug("db_query:$result_msg");
        VIM::DoCommand('let g:dbext_dbi_msg="'.$result_msg.'"');
    }
    # Allow warnings to continue execution
    if ( $DBI::err < 0 ) {
        $result_msg='SQLCode:'.$DBI::err.' Msg:'.db_escape($DBI::errstr);
        db_debug("db_query:$result_msg - exiting");
        VIM::DoCommand('let g:dbext_dbi_msg="'.$result_msg.'"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }

    db_format_results( $sth );

    $sth = undef;

    return 0;
}

db_set_vim_var('msg', '"db_format_results"');
sub db_format_results 
{
    my $sth = shift;

    # if ( ! $DBI::errstr eq "" ) {
    #     VIM::DoCommand('let g:dbext_dbi_msg="SQLCode:'.$DBI::err.' Msg:'.db_escape($DBI::errstr).'"');
    #     VIM::DoCommand('let g:dbext_dbi_result="-1"');
    #     return -1;
    # }

    my $i = 0;
    my $row_count = 0;
    my $max_col_width = 0;
    my $temp_length = 0;
    my $more_results;
    my @col_length;
    my @table;
    my @headers;

    # Check if the NUM_OF_FIELDS is > 0.
    # In mysql a COMMIT does not provide a result set.
    if (  $sth->{NUM_OF_FIELDS} > 0 ) {
        # Add the column list to the array
        push @headers,[ @{$sth->{NAME}} ];
        # Set the initial length of the columns
        foreach my $col_name ( @{$sth->{NAME}}  ) {
            $temp_length = length($col_name);
            $temp_length = ($temp_length > $min_col_width ? $temp_length : $min_col_width);
            $max_col_width = ( $temp_length > $max_col_width ? $temp_length : $max_col_width );
            $col_length[$i] = $temp_length;
            $i++;
        }
        while( my $row = $sth->fetchrow_arrayref()  ) {
            $i = 0;
            push @table,[ @$row ];
            # For every column retrieved, check if it is longer than any of
            # the previous columns.  If so, update the maximum length.
            # This must be done column by column since I am not aware of
            # a way to check the maximum length of an array without checking
            # every entry which we are already doing here.
            foreach my $col ( @{$row} ) {
                $temp_length = length((defined($col)?$col:""));
                $col_length[$i] = ( $temp_length > $col_length[$i] ? $temp_length : $col_length[$i] );
                $i++;
            }

            # Cap the number of rows displayed.
            $row_count++;
            $max_rows = db_vim_eval("g:dbext_dbi_max_rows");
            if ( $max_rows > 0 && $row_count >= $max_rows ) {
                db_debug('Bailing on row count:'.$max_rows);
                last;
            }
        }
        # It is possible for an error to occur only when fetching data.
        # This will capture the error and report it.
        if ( ! $DBI::errstr eq "" ) {
            $result_msg='SQLCode:'.$DBI::err.' Msg:'.db_escape($DBI::errstr);
            VIM::DoCommand('let g:dbext_dbi_msg="'.$result_msg.'"');
            db_debug("db_format_array:$result_msg");
        }
        # Allow warnings to continue execution
        if ( $DBI::err < 0 ) {
            $result_msg='SQLCode:'.$DBI::err.' Msg:'.db_escape($DBI::errstr);
            VIM::DoCommand('let g:dbext_dbi_msg="'.$result_msg.'"');
            db_debug("db_format_array:$result_msg - exiting");
            VIM::DoCommand('let g:dbext_dbi_result="-1"');
            return -1;
        }

        $more_results = $sth->{more_results};

        db_debug("sqlanywhere_more_results:".(defined($sth->{sqlanywhere_more_results})?$sth->{sqlanywhere_more_results}:''));
        if ( $more_results ) {
            db_debug("more_results:true");
        } else {
            db_debug("more_results:false");
        }
    }

    # db_echo(Dumper($sth));
    $sth->finish;

    @result_headers       = @headers;
    @result_set           = @table;
    @result_col_length    = @col_length;
    $result_max_col_width = $max_col_width;

    db_debug("H:".Dumper(@result_headers));
    db_debug("R:".Dumper(@result_set));
    db_debug('db_format_results:result_set:'.Dumper(@result_set));
    db_format_array();

    # Setting the dbext_dbi_result variable to DBI: instructs
    # dbext.vim to call db_print_results() to add the results
    # to the results buffer.
    my $result   = "DBI:";
    if ( defined($result) ) {
        db_debug("db_format_results:Setting result to:$result");
        VIM::DoCommand('let g:dbext_dbi_result="'.$result.'"');
    } else {
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }

    return 0;
}

db_set_vim_var('msg', '"db_format_array"');
sub db_format_array()
{
    # For each row returned concatenate the columns together
    my $result   = "DBI:";
    my $fragment = "";
    my $i;
    # print Dumper( @result_set);
    db_debug( "db_format_results:".$result );
    foreach my $row2 ( @result_set ) {
        $i = 0;
        $fragment = "";
        # Ensure each column is the maximum width for the column by
        # blank padding each string.
        # Add an additional 3 spaces between columns.
        foreach my $col2 ( @{$row2} ) {
            $fragment = substr ((defined($col2)?$col2:"NULL").(' ' x $result_col_length[$i]), 0, $result_col_length[$i]);
            $col2 = $fragment;
            $i++;
        }
        # Finally, escape any double quotes with a preceeding slash
        $result = db_escape($result) . "\n";
    }
    db_debug('db_format_array:result_set:'.Dumper(@result_set));

    return 0;
}

db_set_vim_var('msg', '"db_print_results"');
sub db_print_results 
{
    my $format = shift;
    my $last_line = $main::curbuf->Count();
    my $row_count = 0;
    my $i = 0;
    my $line = "";
    my $fragment = "";
    my $col_name = "";

    if ( ! defined($format) ) {
        $format = "horizontal";
    }
    # db_echo("db_print_results: $format");

    if ( ! $result_msg eq "" ) {
        db_vim_print($last_line, $result_msg);
        $result_msg    = "";
        $last_line++;
    }
    if ( $format eq "horizontal" ) {
        # Print column names
        foreach my $row2 ( @result_headers ) {
            $i = 0;
            $fragment = "";
            $line = "";
            # Ensure each column is the maximum width for the column by
            # blank padding each string.
            # Add an additional 3 spaces between columns.
            foreach my $col2 ( @{$row2} ) {
                $fragment = substr ((defined($col2)?$col2:"").(' ' x $result_col_length[$i]), 0, $result_col_length[$i]);
                $line .= db_remove_newlines($fragment).$col_sep_vert;
                $i++;
            }
            # Finally, escape any double quotes with a preceeding slash
            db_vim_print($last_line, $line);
            $last_line++;
        }
        # Print underlines for each column the width of the
        # largest column value
        $i = 0;
        $line = "";
        while ($i < scalar(@result_col_length) ) {
            $line .= '-' x $result_col_length[$i].$col_sep_vert;
            $i++;
        }
        db_vim_print($last_line, $line);
        $last_line++;

        # Print each row
        foreach my $row3 ( @result_set ) {
            $row_count++;
            # db_echo("db_print_results: row count:$row_count");
            $line = "";
            foreach my $col3 ( @{$row3} ) {
                $line .= $col3.$col_sep_vert;
            }
            db_vim_print($last_line, db_remove_newlines($line));
            $last_line++;
        }
    } else {
        my @formatted_headers;
        my $col_nbr = 0;
        my $max_col_width = $result_max_col_width + 1;
        $i = 0;
        while ($i < scalar(@result_col_length) ) {
            $fragment = "";
            $col_name = (defined($result_headers[0][$i])?$result_headers[0][$i]:"");
            $col_name .= ':';
            # Left justified
            # $fragment = substr ($col_name.(' ' x $max_col_width), 0, $max_col_width);
            # Right justified
            $fragment = substr ((' ' x $max_col_width).$col_name, -$max_col_width, $max_col_width);
            $formatted_headers[$i] = $fragment;
            $i++;
        }
        
        my $lines_printed = 0;
        foreach my $row4 ( @result_set ) {
            $row_count++;
            # db_echo("db_print_results: row count:$row_count");
            $col_nbr = 0;
            db_vim_print($last_line, "****** Row: $row_count ******");
            $last_line++;
            $lines_printed = 0;
            foreach my $col4 ( @{$row4} ) {
                $fragment = "";
                $line = "";
                $line .= $formatted_headers[$col_nbr].' '.$col4;
                $lines_printed = db_vim_print($last_line, db_escape($line));
                $last_line += $lines_printed;
                $col_nbr++;
            }
        }
    }
    db_vim_print($last_line, "(".scalar(@result_set)." rows)");
    return 0;
}

db_set_vim_var('msg', '"db_results_variable"');
sub db_results_variable
{
    my $format = shift;
    my $row_count = 0;
    my $i = 0;
    my $line = "";
    my $fragment = "";
    my $col_name = "";
    my $result   = "DBI:";

    if ( ! defined($format) ) {
        $format = "horizontal";
    }
    # db_echo("db_print_results: $format");

    if ( ! $result_msg eq "" ) {
        $result .= db_escape($result_msg)."\n";
        $result_msg    = "";
    }
    if ( $format eq "horizontal" ) {
        # Print column names
        foreach my $row2 ( @result_headers ) {
            $i = 0;
            $fragment = "";
            $line = "";
            # Ensure each column is the maximum width for the column by
            # blank padding each string.
            # Add an additional 3 spaces between columns.
            foreach my $col2 ( @{$row2} ) {
                $fragment = substr ((defined($col2)?$col2:"").(' ' x $result_col_length[$i]), 0, $result_col_length[$i]);
                $line .= db_remove_newlines($fragment).'  ';
                $i++;
            }
            # Finally, escape any double quotes with a preceeding slash
            $result .= db_escape($line)."\n";
        }
        # Print underlines for each column the width of the
        # largest column value
        $i = 0;
        $line = "";
        while ($i < scalar(@result_col_length) ) {
            $line .= '-' x $result_col_length[$i].'  ';
            $i++;
        }
        $result .= db_escape($line)."\n";

        # Print each row
        foreach my $row2 ( @result_set ) {
            $row_count++;
            # db_echo("db_print_results: row count:$row_count");
            $line = "";
            foreach my $col2 ( @{$row2} ) {
                $line .= $col2.'  ';
            }
            $result .= db_escape($line)."\n";
        }
    } else {
        my @formatted_headers;
        my $col_nbr = 0;
        my $max_col_width = $result_max_col_width + 1;
        $i = 0;
        while ($i < scalar(@result_col_length) ) {
            $fragment = "";
            $col_name = (defined($result_headers[0][$i])?$result_headers[0][$i]:"");
            $col_name .= ':';
            # Left justified
            # $fragment = substr ($col_name.(' ' x $max_col_width), 0, $max_col_width);
            # Right justified
            $fragment = substr ((' ' x $max_col_width).$col_name, -$max_col_width, $max_col_width);
            $formatted_headers[$i] = $fragment;
            $i++;
        }
        
        foreach my $row2 ( @result_set ) {
            $row_count++;
            # db_echo("db_print_results: row count:$row_count");
            $col_nbr = 0;
            $result .= "****** Row: $row_count ******\n";
            foreach my $col2 ( @{$row2} ) {
                $fragment = "";
                $line = "";
                $line .= $formatted_headers[$col_nbr].' '.$col2;
                $result .= db_escape($line);
                $col_nbr++;
            }
        }
    }
    $result .= "(".scalar(@result_set)." rows)\n";

    if ( defined($result) ) {
        db_debug("db_format_results:Setting result to:$result");
        VIM::DoCommand('let g:dbext_dbi_result="'.$result.'"');
    } else {
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }

    return 0;
}

db_set_vim_var('msg', '"db_results_list"');
sub db_results_list
{
    my $show_headers = shift;
    my $format = shift;
    my $row_count = 0;
    my $i = 0;
    my $line = "";
    my $fragment = "";
    my $col_name = "";
    my $result   = "DBI:";

    if ( ! defined($format) ) {
        $format = "horizontal";
    }
    if ( ! defined($show_headers) ) {
        $show_headers = 1;
    }
    # db_echo("db_print_results: $format");

    VIM::DoCommand('let g:dbext_dbi_result=[]');
    if ( $format eq "horizontal" ) {
        # Print column names
        if ( $show_headers == 1 ) {
            foreach my $row2 ( @result_headers ) {
                $line = join("','", @{$row2});
                if ( scalar(@{$row2}) > 0 ) {
                    $line = "'".$line."'";
                }
                $line = 'call add(g:dbext_dbi_result, ['.$line.']';
                # Escape any double quotes with a preceeding slash
                $line = db_escape($line)."\n";
                VIM::DoCommand($line);;
            }
        }

        # Print each row
        foreach my $row2 ( @result_set ) {
            $line = join("','", @{$row2});
            if ( scalar(@{$row2}) > 0 ) {
                $line = "'".$line."'";
            }
            $line = 'call add(g:dbext_dbi_result, ['.$line.']';
            # Escape any double quotes with a preceeding slash
            $line = db_escape($line)."\n";
            VIM::DoCommand($line);;
        }
    } else {
        my @formatted_headers;
        my $col_nbr = 0;
        my $max_col_width = $result_max_col_width + 1;
        $i = 0;
        while ($i < scalar(@result_col_length) ) {
            $fragment = "";
            $col_name = (defined($result_headers[0][$i])?$result_headers[0][$i]:"");
            $col_name .= ':';
            # Left justified
            # $fragment = substr ($col_name.(' ' x $max_col_width), 0, $max_col_width);
            # Right justified
            $fragment = substr ((' ' x $max_col_width).$col_name, -$max_col_width, $max_col_width);
            $formatted_headers[$i] = $fragment;
            $i++;
        }
        
        foreach my $row2 ( @result_set ) {
            $row_count++;
            # db_echo("db_print_results: row count:$row_count");
            $col_nbr = 0;
            $result .= "****** Row: $row_count ******\n";
            foreach my $col2 ( @{$row2} ) {
                $fragment = "";
                $line = "";
                $line .= $formatted_headers[$col_nbr].' '.$col2;
                $result .= db_escape($line);
                $col_nbr++;
            }
        }
    }

    return 0;
}

db_set_vim_var('msg', '"db_catalogue"');
sub db_catalogue 
{
    my $request_type = shift;
    my $result       = undef;
    my $object_type  = undef;
    my $catalogue    = undef;
    my $schema       = undef;
    my $table        = undef;
    my $column       = '%';
    my $conn_local;

    # $debug         = db_is_debug();
    if ( length($request_type) == 0 ) {
        VIM::DoCommand('let g:dbext_dbi_msg="A request_type must be specified"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }
    if ( ! db_is_connected() ) {
        db_debug("You must connect first");
        VIM::DoCommand('let g:dbext_dbi_msg="You are not connected to a database"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }

    $conn_local = db_get_connection();
    my $sth = undef;

    if ( $request_type eq 'TABLE' || $request_type eq 'VIEW' ) {
        $object_type = shift;
        $schema      = shift;
        $table       = shift;

        db_debug("db_catalogue using the following:".(defined($catalogue)?$catalogue:"").":".(defined($schema)?$schema:"").":".(defined($table)?$table:"").":".(defined($object_type)?$object_type:""));
        # Working call would be 
        #      table_info(undef, undef, undef, '%TABLE%');
        #      table_info(undef, undef, 'c%', '%TABLE%');
        #      table_info(undef, 'DB%', 'c%', '%TABLE%');
        eval {
            $sth = $conn_local->table_info($catalogue, $schema, $table, $object_type);
        };
    }
    if ( $request_type eq 'COLUMN' ) {
        $schema           = shift;
        $table            = shift;

        db_debug("db_catalogue using the following:".(defined($catalogue)?$catalogue:"").":".(defined($schema)?$schema:"").":".(defined($table)?$table:"").":".(defined($object_type)?$object_type:""));

        # Working calls would be:
        #      column_info(undef, undef, 'customers', '%');
        #      column_info(undef, 'DBA', 'customers', '%');
        eval {
            $sth = $conn_local->column_info($catalogue, $schema, $table, $column);
        };
    }
    
    if ($@) {
        db_debug("db_catalogue statement error for request type:$request_type\n".db_escape($@));
        VIM::DoCommand('let g:dbext_dbi_msg="Invalid statement for request type:'.$request_type."\n".db_escape($@).'"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }
    if ( defined($sth) ) {
        db_debug("db_catalogue statement is defined");
        $sth->execute;
        db_format_results( $sth );
    } else {
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        if ( ! $DBI::errstr eq "" ) {
            VIM::DoCommand('let g:dbext_dbi_msg="SQLCode:'.$DBI::err.' Msg:'.db_escape($DBI::errstr).'"');
        } else {
            VIM::DoCommand('let g:dbext_dbi_msg="Statement failed, request_type:'.$request_type.'"');
        }
        db_debug("db_catalogue statement failed:".$DBI::err.":".$DBI::errstr);
        return -1;
    }

    return 0;
}

db_set_vim_var('msg', '"db_odbc_catalogue"');
sub db_odbc_catalogue 
{
    # A reference page for some of the function available can be found here:
    #    http://search.cpan.org/~timb/DBD-ODBC-0.20/ODBC.pm

    my $request_type = shift;
    my $result       = undef;
    my $object_type  = undef;
    my $catalogue    = undef;
    my $schema       = undef;
    my $table        = undef;
    my $column       = '%';
    my $conn_local;

    # $debug         = db_is_debug();
    if ( length($request_type) == 0 ) {
        db_debug("db_odbc_catalogue: A request type must be specified");
        VIM::DoCommand('let g:dbext_dbi_msg="A request_type must be specified"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }
    if ( ! db_is_connected() ) {
        db_debug("db_odbc_catalogue: You are not connected to a database");
        VIM::DoCommand('let g:dbext_dbi_msg="You are not connected to a database"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }

    $conn_local = db_get_connection();
    my $sth = undef;

    if ( $request_type eq 'TABLE' || $request_type eq 'VIEW' ) {
        # my $object_type = '%';
        # my $object_type = 'TABLE';
        # my $schema      = '%';
        # my $table       = '%';
        # my $table       = '';
        # my $table       = 'Employees';
        # my $table       = '%';
        $object_type = shift;
        $schema      = shift;
        $table       = shift;

        db_debug("db_odbc_catalogue using the following:".(defined($catalogue)?$catalogue:"").":".(defined($schema)?$schema:"").":".(defined($table)?$table:"").":".(defined($object_type)?$object_type:""));
        eval {
            $sth = $conn_local->table_info($catalogue, $schema, $table, $object_type);
        };
    }
    if ( $request_type eq 'COLUMN' ) {
        # my $object_type = '%';
        # my $object_type = 'TABLE';
        # my $schema      = '%';
        # my $table       = '%';
        # my $table       = '';
        # my $table       = 'Employees';
        # my $table       = '%';
        $schema      = shift;
        $table       = shift;
        $column      = shift;

        db_debug("db_odbc_catalogue using the following:".(defined($catalogue)?$catalogue:"").":".(defined($schema)?$schema:"").":".(defined($table)?$table:"").":".(defined($object_type)?$object_type:""));
        eval {
            $sth = $conn_local->func($catalogue, $schema, $table, $column, 'columns');
        };
    }
    
    if ($@) {
        db_debug("db_odbc_catalogue statement error for request type:$request_type\n".db_escape($@));
        VIM::DoCommand('let g:dbext_dbi_msg="Invalid statement for request type:'.$request_type."\n".db_escape($@).'"');
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        return -1;
    }
    if ( defined($sth) ) {
        db_debug("db_odbc_catalogue statement is defined");
        # Do not execute the statement when calling the func() method
        # http://www.mail-archive.com/dbi-users@perl.org/msg17977.html
        # $sth->execute;
        db_format_results( $sth );
    } else {
        VIM::DoCommand('let g:dbext_dbi_result="-1"');
        if ( ! $DBI::errstr eq "" ) {
            VIM::DoCommand('let g:dbext_dbi_msg="SQLCode:'.$DBI::err.' Msg:'.db_escape($DBI::errstr).'"');
        } else {
            VIM::DoCommand('let g:dbext_dbi_msg="Statement failed, request_type:'.$request_type.'"');
        }
        db_debug("db_odbc_catalogue statement failed:".$DBI::err.":".$DBI::errstr);
        return -1;
    }


    return 0;
}
db_get_defaults();
db_set_vim_var('msg', '"Perl subroutines ready"');
db_set_vim_var('result', '""');

EOCore

    " echomsg "Finished loading Perl subroutines"
    let g:dbext_dbi_loaded_perl_subs = 1
endfunction

" vim:fdm=marker:nowrap:ts=4:expandtab:ff=unix:
