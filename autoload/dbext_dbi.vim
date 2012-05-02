" File:          dbext_dbi.vim
" Copyright (C) 2002-10, Peter Bagyinszki, David Fishburn
" Purpose:       A perl extension for use with dbext.vim. 
"                It adds transaction support and the ability
"                to reach any database currently supported
"                by Perl and DBI.
" Version:       15.00
" Maintainer:    David Fishburn <dfishburn dot vim at gmail dot com>
" Authors:       David Fishburn <dfishburn dot vim at gmail dot com>
" Last Modified: 2012 Apr 05
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
"        cd %SQLANY11%\SDK\perl
"        copy "%SQLANYSAMP11%\demo.db"
"        dbeng11 demo
"
"        cd %SQLANY12%\SDK\perl
"        copy "%SQLANYSAMP12%\demo.db"
"        dbeng12 demo
"
"        Make sure SQLANY(10|11|12) is in your path before any other versions of SQL
"        Anywhere.
"        "C:\Program Files\Microsoft Visual Studio .Net 2003\Common7\Tools\vsvars32.bat"
"        or
"        "C:\Program Files\Microsoft Visual Studio 8\Common7\Tools\vsvars32.bat"
"        or
"        "C:\Program Files (x86)\Microsoft Visual Studio 9.0\Common7\Tools\vsvars32.bat"
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
let g:loaded_dbext_dbi = 1500

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

" Turn on support for line continuations when creating the script
let s:cpo_save = &cpo
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

BEGIN {(*STDERR = *STDOUT) || die;} 

use diagnostics;
use warnings;
use strict;
use Data::Dumper qw( Dumper );
use DBI;

my %connections;
my @result_headers;
my @result_set;
my @result_col_length;
my $result_max_col_width;
my $max_rows      = 300;
my $min_col_width = 4;   # First NULL
my $test_inc      = 0;
my $conn_inc      = 0;
my $dbext_dbi_sql = "";
my $col_sep_vert  = "  ";
my $debug         = 0;
my $inside_vim    = 0;
my $native_err    = 0;


sub db_set_vim_var
{
    my $var_name = shift;
    my $string   = shift;
    my $let      = ('let '.$var_name.'="'.db_escape($string).'"');
    if( $inside_vim ) {
        # db_echo('db_set_vim_var:'.$let);
        VIM::DoCommand($let);
        # db_echo('db_set_vim_var finished');
    } else {
        print('let '.$var_name.'="'.$string."\"\n");
    }
}


db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_trim_white_space');
sub db_trim_white_space($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}


db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_echo');
sub db_echo 
{
    my $msg = shift;

    # VIM::Msg('DBI:'.$msg, 'WarningMsg');
    db_vim_op( "Msg", 'DBI:'.$msg );
    return 0;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_debug');
sub db_debug 
{
    my $msg = shift;
    $debug and db_echo($msg);
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_is_debug');
sub db_is_debug 
{
    return db_vim_eval('g:dbext_dbi_debug');
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_vim_check_inside');
sub db_vim_check_inside 
{
    eval {
        VIM::Eval(1);
    };
    if ($@) {
        db_debug("Not inside Vim:".$@);
        $inside_vim = 0;
    } else {
        db_debug("Inside Vim:".$@);
        $inside_vim = 1;
    }
    return;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_vim_eval');
sub db_vim_eval 
{
    my $cmd = shift;
    my $rc;
    my $val;

    if( ! $inside_vim ) {
        if( $cmd eq "bufnr('%')" ) {
            return 1;
        }
        if( $cmd eq "g:dbext_dbi_max_rows" ) {
            return 10;
        }
        if( $cmd eq "g:dbext_default_dbi_column_delimiter" ) {
            return "\t";
        }
    }
    if( defined($cmd) ) {
        if( $inside_vim ) {
            # return VIM::Eval($cmd);
            ($rc, $val) = VIM::Eval($cmd);
            # db_echo("db_vim_eval:$cmd:$rc:$val");
            if( $rc == 1 ) {
                return $val;
            } else {
                return -1;
            }
        } else {
            return ($cmd);
        }
    }
    return "";
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_vim_op');
sub db_vim_op 
{
    my $op            = shift;

    if( ! defined($op) ) {
        return;
    }

    if( $op eq "Count" ) {
        if( $inside_vim ) {
            return $main::curbuf->Count();
        } else {
            return 1;
        }
    } elsif ( $op eq "Append" ) {
        my $line_nbr      = shift;
        my $line_txt      = shift;
        if( ! defined($line_nbr) ) {
            $line_nbr = "";
        }
        if( ! defined($line_txt) ) {
            $line_txt = "";
        }
        if( $inside_vim ) {
            $main::curbuf->Append($line_nbr, $line_txt);
        } else {
            print "$line_txt\n";
        }
    } elsif ( $op eq "call" ) {
        my $cmd      = shift;
        if( ! defined($cmd) ) {
            $cmd = "";
        }
        if( $inside_vim ) {
            VIM::DoCommand($cmd);
        } else {
            print "Vim:DoCommand:$cmd\n";
        }
    } else {
        # Msg
        my $msg      = shift;
        if( ! defined($msg) ) {
            $msg = "";
        }
        if( $inside_vim ) {
            VIM::Msg('DBI:'.$msg, 'WarningMsg');
        } else {
            print "$msg\n";
        }
    }
    return "";
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_vim_print');
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
        # $main::curbuf->Append($line_nbr, $line);
        db_vim_op("Append", $line_nbr, $line);
        $line_nbr++;
        $printed_lines++;
    }
    return $printed_lines;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_get_defaults');
sub db_get_defaults 
{
    $col_sep_vert = db_vim_eval('g:dbext_default_dbi_column_delimiter');
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_escape');
sub db_escape 
{
    my $escaped = shift;
    if( defined($escaped) ) {
        $escaped =~ s/"/\\"/g;
        $escaped =~ s/\\/\\\\/g;
        $escaped =~ s/\n/\\n/g;
    }

    return $escaped;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_remove_newlines');
sub db_remove_newlines 
{
    my $escaped = shift;
    $escaped =~ s/\n/ /g;

    return $escaped;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_get_available_drivers');
sub db_get_available_drivers 
{
    my @ary = DBI->available_drivers;
    db_echo('db_available_drivers:'.Dumper(@ary));
    return 0;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_list_connections');
sub db_list_connections
{
    db_debug('db_list_connections:'.Dumper(%connections));
    my @row;
    my @table;
    my @col_length;
    my $max_col_width = 0;
    my $i = 0;
    my @headers = [ ("Buffer", "Driver", "AutoCommit", "CommitOnDisconnect", "Connection Parameters", "LongReadLen", "FileName") ];
    
    db_set_vim_var("g:dbext_dbi_msg", '');
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
                    , $connections{$bufnr}->{'conn'}->{'AutoCommit'}
                    , $connections{$bufnr}->{'CommitOnDisconnect'}
                    , $connections{$bufnr}->{'params'}
                    , $connections{$bufnr}->{'conn'}->{'LongReadLen'}
                    , db_vim_eval('fnamemodify( bufname( bufnr('.$bufnr.')), ":p:t")' )
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
        push @result_set, [ ("There are no active DBI connections", "", "", "", "", "") ];
    } 
    db_debug('db_list_connections:final:'.Dumper(@result_set));
    # TODO 
    # This should define an array so db_print_results can be used
    db_set_vim_var("g:dbext_dbi_result", 'DBI:');
    db_set_vim_var("g:dbext_dbi_msg", '');
    return 0;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_get_info');
sub db_get_info
{
    my $option = shift;

    my $conn_local;
    my $driver;

    if ( ! db_is_connected() ) {
        db_echo("db_get_info:You must connect first");
        return -1;
    }

    ($conn_local, $driver) = db_get_connection();

    my $result = "";

    if ( defined($option) ) {
        $result = $conn_local->get_info($option);
    } else {
        $result = "DBMS Name[".$conn_local->get_info(17).
                "] Version[".$conn_local->get_info(18)."]";
    }

    db_debug('db_get_info:'.$result);
    db_set_vim_var("g:dbext_dbi_result", $result);
    return 0;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_commit');
sub db_commit 
{
    my $conn_local;
    my $driver;

    db_debug("Committing connection");
    if ( ! db_is_connected() ) {
        db_set_vim_var("g:dbext_dbi_result", -1);
        db_set_vim_var("g:dbext_dbi_msg", 'You are not connected to a database');
        return -1;
    }

    ($conn_local, $driver) = db_get_connection();

    my $rc = $conn_local->commit;
    db_set_vim_var("g:dbext_dbi_result", $rc);
    return $rc;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_rollback');
sub db_rollback 
{
    my $conn_local;
    my $driver;
    
    db_debug("Rolling back connection");
    if ( ! db_is_connected() ) {
        db_set_vim_var("g:dbext_dbi_result", -1);
        db_set_vim_var("g:dbext_dbi_msg", 'You are not connected to a database');
        return -1;
    }

    ($conn_local, $driver) = db_get_connection();
        
    my $rc = $conn_local->rollback;
    db_set_vim_var("g:dbext_dbi_result", $rc);
    return $rc;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_is_connected');
sub db_is_connected 
{
    my $bufnr        = shift;
    my $is_connected = 0;
    my $conn_local;
    $test_inc++;
    db_debug('db_is_connected:test_inc:'.$test_inc);
    
    if( ! defined($bufnr) ) {
        db_debug('db_is_connected:$bufnr undefined');
        $bufnr        = db_vim_eval("bufnr('%')");
        db_debug("db_is_connected:looking up $bufnr");
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
    db_set_vim_var("g:dbext_dbi_result", $is_connected);
    return $is_connected;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_get_connection');
sub db_get_connection 
{
    my $bufnr        = shift;
    my $driver       = '';
    my $conn_local;
    
    if( ! defined($bufnr) ) {
        db_debug('db_get_connected:$bufnr undefined');
        $bufnr        = db_vim_eval("bufnr('%')");
        db_debug("db_get_connection:looking up $bufnr");
    }
    if ( ! db_is_connected($bufnr) ) {
        db_debug('db_get_connection:connection not found:'.$bufnr);
        return undef;
    }

    db_debug('db_get_connection:returning:'.$bufnr);
    $conn_local = $connections{$bufnr}->{'conn'};
    $driver     = $connections{$bufnr}->{'driver'};
    return ($conn_local, $driver);
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_check_error');
sub db_check_error 
{
    my $err    = 0;
    my $level  = '';
    my $msg    = '';
    my $state  = '';
    my $bufnr  = '';
    my $driver = shift;
    my $conn_local;

    if ( defined($DBI::err) && defined($DBI::errstr) && defined($DBI::state) ) {

        if( ! defined($driver) ) {
            ($conn_local, $driver) = db_get_connection();
        }
        db_debug("db_check_error:$bufnr:$driver");

        $err   = $DBI::err;
        $msg   = $DBI::errstr;
        $state = $DBI::state;

        # db_echo("db_check_error: initial values:$level:$err:$state:$msg");
        if( $driver eq "ODBC" ) {
            if ( $err eq "" && ! $msg eq "" ) {
                # Informational message
                $level = "I";
            } elsif ( $err eq "0" && ! $msg eq "" ) {
                # Warning message
                $level = "W";
            } elsif ( $err eq "1" && ! $msg eq "" ) {
                # Error message
                $level = "E";
            }
            if( defined($native_err) ) {
                $err = $native_err;
            }
        } else {
            if ( ($err eq "" || $err eq "0") && ! $msg eq "" ) {
                # Informational message
                $level = "I";
            } elsif ( $err gt "0" && ! $msg eq "" ) {
                # Warning message
                $level = "W";
            } elsif ( $err lt "0" && ! $msg eq "" ) {
                # Error message
                $level = "E";
            }
        }
    }

    db_debug("db_check_error: returning:$level:$err:$state:$msg");
    return ($level, $err, $msg, $state);
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_odbc_err_handler');
sub db_odbc_err_handler 
{
   my ($state, $msg, $native) = @_;
   $native_err = $native;
   # db_echo("db_odbc_err_handler: native error:$native_err");

   # Do not ignore the error
   return 1;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_connect');
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
        db_set_vim_var("g:dbext_dbi_msg", 'E. Invalid driver:'.$driver);
        db_set_vim_var("g:dbext_dbi_result", -1);
        return -1;
    }
    if ( ! defined($uid) ) {
        # db_echo("Invalid userid:$uid");
        db_set_vim_var("g:dbext_dbi_msg", 'E. Invalid userid:'.$uid);
        db_set_vim_var("g:dbext_dbi_result", -1);
        return -1;
    }
    if ( ! defined($pwd) ) {
        # db_echo("Invalid password:$pwd");
        db_set_vim_var("g:dbext_dbi_msg", 'E. Invalid password:'.$pwd);
        db_set_vim_var("g:dbext_dbi_result", -1);
        return -1;
    }

    my $DATA_SOURCE = "DBI:$driver:$conn_parms";

    db_debug('db_connected:connecting to:'.$DATA_SOURCE);
    # Use global connection object
    eval {
        # LongReadLen sets the maximum size of a BLOB that 
        # can be retrieved from the database.
        # This value can be overriden from your connection string
        # or by using:
        #     DBSetOption LongReadLen=4096
        #     DBSetOption driver_parms=LongReadLen=4096
        #
        # LongTruncOk indicates to allow data truncation,
        # and do not report an error.
        $conn_local = DBI->connect( $DATA_SOURCE, $uid, $pwd,
                    { AutoCommit => 1, 
                    LongReadLen => 1000, 
                    LongTruncOk => 1, 
                    RaiseError => 0, 
                    PrintError => 0, 
                    PrintWarn => 0 } 
                    );
        # or die $DBI::errstr;
    };

    if ($@) {
        db_set_vim_var('g:dbext_dbi_msg', "Cannot connect to data source:".$DATA_SOURCE." using:".$uid." E:".$@);
        db_set_vim_var('g:dbext_dbi_result', -1);
        return -1;
    }
    my( $level, $err, $msg, $state ) = db_check_error($driver);
    if ( ! $msg eq "" ) {
        $msg = "$level. DBC:".(($level ne "I")?"SQLCode:$err:":"").$msg.(($state ne "")?":$state":"").":\nConnection details:$DATA_SOURCE";
        db_set_vim_var('g:dbext_dbi_msg', $msg);
        if ( $level eq "E" ) {
            db_set_vim_var('g:dbext_dbi_result', -1);
            db_debug("db_connect:$msg - exiting");
            return -1;
        }
    }

    if ( $driver eq "ODBC" ) {
        db_debug("db_connect: Enabling odbc_err_handler");
        $conn_local->{odbc_err_handler} = \&db_odbc_err_handler;
    }

    $connections{$bufnr} = {'conn'               => $conn_local
                           ,'driver'             => $driver
                           ,'uid'                => $uid
                           ,'params'             => $conn_parms
                           ,'AutoCommit'         => 1
                           ,'CommitOnDisconnect' => 1
                           ,'LastRequest'        => localtime
                           };
    # db_debug('db_connected:checking if successful');
    # if ( ! db_is_connected() ) {
    #     db_set_vim_var('g:dbext_dbi_msg', "Cannot connect to data source:$DATA_SOURCE using:$uid SQLCode:".$DBI::err.":".db_escape($DBI::errstr));
    #     db_set_vim_var("g:dbext_dbi_result", -1);
    #     return -1;
    # }

    my $trace_level = db_vim_eval("g:dbext_dbi_trace_level");
    if ( ! $trace_level eq "0" ) {
        my $vim_dir = db_vim_eval("expand('".'$VIM'."')");
        $conn_local->trace($trace_level, $vim_dir.'\dbi_trace.txt');
    }
    return 0;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_disconnect');
sub db_disconnect
{
    my $bufnr        = shift;
    my $conn_local;
    my $driver;

    db_set_vim_var('g:dbext_dbi_result', 0);

    if( ! defined($bufnr) ) {
        db_debug('db_disconnect:$bufnr is undefined');
        $bufnr        = db_vim_eval("bufnr('%')");
        db_debug("db_disconnect:looking up $bufnr");
    }
    db_debug('db_disconnect:checking for existing connection:'.$bufnr);
    if ( ! db_is_connected($bufnr) ) {
        return 0;
    }

    ($conn_local, $driver) = db_get_connection($bufnr);

    if( ! defined($conn_local) ) {
        db_debug('db_disconnect:This should not have happened since this buffer was connected:'.$bufnr);
        db_set_vim_var('g:dbext_dbi_result', -1);
        db_set_vim_var('g:loaded_dbext_dbi_msg', "db_disconnect:This should not have happened since this buffer was connected:$bufnr");
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

    db_set_vim_var('g:dbext_dbi_result', 1);
    return 0;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_disconnect_all');
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


db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_get_connection_option');
sub db_get_connection_option
{
    my $option = shift;
    my $conn_local;
    my $driver;

    $debug         = db_is_debug();
    if ( ! defined($option) ) {
        db_debug("An option and value must be specified");
        db_set_vim_var('g:dbext_dbi_msg', "An option must be specified");
        db_set_vim_var('g:dbext_dbi_result', -1);
        return -1;
    }

    if ( ! db_is_connected() ) {
        db_debug("You are not connected to a database");
        db_set_vim_var('g:dbext_dbi_msg', "You are not connected to a database");
        db_set_vim_var('g:dbext_dbi_result', -1);
        return -1;
    }

    ($conn_local, $driver) = db_get_connection();
    if ( ! defined($conn_local->{$option}) ) {
        db_debug("Option[$option] does not exist");
        db_set_vim_var('g:dbext_dbi_msg', "Option[".$option."] does not exist");
        db_set_vim_var('g:dbext_dbi_result', -1);
        return -1;
    }

    # Use global connection object
    # This expecting a boolean value (ie AutoCommit)
    db_set_vim_var('g:dbext_dbi_msg', "");
    db_set_vim_var('g:dbext_dbi_result', $conn_local->{$option});
    #    or die $DBI::errstr;
    return 0;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_set_connection_option');
sub db_set_connection_option
{
    my $option = shift;
    my $value  = shift;
    my $bufnr  = db_vim_eval("bufnr('%')");
    my $conn_local;
    my $driver = '';

    ($conn_local, $driver) = db_get_connection();

    $debug         = db_is_debug();
    if ( ! defined($option) || ! defined($value) ) {
        db_debug("Option and value must be specified");
        db_set_vim_var('g:dbext_dbi_msg', "Option and value must be specified");
        db_set_vim_var('g:dbext_dbi_result', -1);
        return -1;
    }

    if ( ! db_is_connected() ) {
        db_debug("You are not connected to a database");
        db_set_vim_var('g:dbext_dbi_msg', "You are not connected to a database");
        db_set_vim_var('g:dbext_dbi_result', -1);
        return -1;
    }

    if ( $option eq 'DBI_commit_on_disconnect' ) {
        $connections{$bufnr}->{'CommitOnDisconnect'} = $value;
        db_debug("db_set_connection_option Conn[$bufnr]->Opt[$option] Val:[".$connections{$bufnr}->{'CommitOnDisconnect'}."]");
    } else {
        # Use global connection object
        # This expecting a boolean value (ie AutoCommit)
        $conn_local->{$option} = $value;
        #    or die $DBI::errstr;
        db_debug("db_set_connection_option ConnLocal->Opt[$option] Val:[".$conn_local->{$option}."]");

        my( $level, $err, $msg, $state ) = db_check_error($driver);
        if ( ! $msg eq "" ) {
            $msg = "$level. DBSO:".(($level ne "I")?"SQLCode:$err:":"").$msg.(($state ne "")?":$state":"");
            db_set_vim_var('g:dbext_dbi_msg', $msg);
            if ( $level eq "E" ) {
                db_set_vim_var('g:dbext_dbi_result', -1);
                db_debug("db_query:$msg - exiting");
                return -1;
            }
        }
    }

    db_set_vim_var('g:dbext_dbi_msg', "");
    db_set_vim_var('g:dbext_dbi_result', "1");
    return 0;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_query');
sub db_query 
{
    my $sql = shift;
    my $conn_local;
    my $driver = '';
    if ( ! defined($sql) ) {
        $sql = '';
    }

    $debug         = db_is_debug();
    # db_debug("db_query:SQL:".$sql);
    if ( length($sql) == 0 ) {
        $sql       = db_vim_eval('g:dbext_dbi_sql');
        db_debug("db_query:SQL after eval:".$sql);
    }
    if ( length($sql) == 0 ) {
        db_set_vim_var("g:dbext_dbi_result", -1);
        db_set_vim_var("g:dbext_dbi_msg", 'No statement to exeucte');
        return -1;
    }
    if ( ! db_is_connected() ) {
        db_debug("db_query:You must connect first");
        db_set_vim_var("g:dbext_dbi_result", -1);
        db_set_vim_var("g:dbext_dbi_msg", 'You must connect first');
        return -1;
    }
 
    ($conn_local, $driver) = db_get_connection();
    my $sth = undef;
    $conn_local->{LastRequest} = localtime;

    $sth = $conn_local->prepare( $sql );
    # db_echo( "db_query:25".DBI::errstr );
    # db_debug("db_query:prepared:".$sql);
    # It is possible for an error to occur only when fetching data.
    # This will capture the error and report it.
    # if ( defined($DBI::err) && defined($DBI::errstr) ) {
    #     if ( $DBI::err eq "" && ! $DBI::errstr eq "" ) {
    #         # Informational message
    #         db_set_vim_var('g:dbext_dbi_msg', 'I. DBQp:'.db_escape($DBI::errstr));
    #     } elsif ( $DBI::err gt 0 && ! $DBI::errstr eq "" ) {
    #         # Warning message
    #         db_set_vim_var('g:dbext_dbi_msg', 'W. DBQp:SQLCode:'.$DBI::err.":".db_escape($DBI::errstr).":".db_escape($DBI::state));
    #         db_debug("db_query:$result_msg");
    #     } elsif ( ! $DBI::errstr eq "" ) {
    #         # Error message
    #         db_set_vim_var('g:dbext_dbi_msg', 'E. DBQp:SQLCode:'.$DBI::err.":".db_escape($DBI::errstr).":".db_escape($DBI::state));
    #         db_set_vim_var('g:dbext_dbi_result', -1);
    #         db_debug("db_query:$result_msg - exiting");
    #         return -1;
    #     }
    # }

    my( $level, $err, $msg, $state ) = db_check_error($driver);
    if ( ! $msg eq "" ) {
        $msg = "$level. DBQp:".(($level ne "I")?"SQLCode:$err:":"").$msg.(($state ne "")?":$state":"");
        db_set_vim_var('g:dbext_dbi_msg', $msg);
        if ( $level eq "E" ) {
            db_set_vim_var('g:dbext_dbi_result', -1);
            db_debug("db_query:$msg - exiting");
            return -1;
        }
    }


    my $row_count = $sth->execute;
    db_debug("db_query:rowcount[$row_count] executed[$sql]");
    if ( $row_count eq "0E0" || $row_count lt "0" ) {
        # 0E0 - Special case which means no rows were affected
        # -1  - Can be returned if executing DDL (as an example)
        $row_count = 0;
    }
    db_set_vim_var('g:dbext_rows_affected', $row_count);
    ( $level, $err, $msg, $state ) = db_check_error($driver);
    if ( ! $msg eq "" ) {
        $msg = "$level. DBQe:".(($level ne "I")?"SQLCode:$err:":"").$msg.(($state ne "")?":$state":"");
        db_set_vim_var('g:dbext_dbi_msg', $msg);
        if ( $level eq "E" ) {
            db_set_vim_var('g:dbext_dbi_result', -1);
            db_debug("db_query:$msg - exiting");
            return -1;
        }
    }

    db_format_results( $sth );

    $sth = undef;

    return 0;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_format_results');
sub db_format_results 
{
    my $sth = shift;

    my $i = 0;
    my $row_count = 0;
    my $max_col_width = 0;
    my $temp_length = 0;
    my $more_results;
    my $conn_local;
    my $driver;
    my @col_length;
    my @table;
    my @headers;

    ($conn_local, $driver) = db_get_connection();

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
        my( $level, $err, $msg, $state ) = db_check_error($driver);
        if ( ! $msg eq "" ) {
            $msg = "$level. DBfr:".(($level ne "I")?"SQLCode:$err:":"").$msg.(($state ne "")?":$state":"");
            db_set_vim_var('g:dbext_dbi_msg', $msg);
            if ( $level eq "E" ) {
                db_set_vim_var('g:dbext_dbi_result', -1);
                db_debug("db_format_results:$msg - exiting");
                return -1;
            }
        }

        db_set_vim_var('g:dbext_rows_affected', $row_count);

        if( $driver eq "ODBC" ) {
            $more_results = $sth->{odbc_more_results};
        } else {
            $more_results = $sth->{more_results};
        }

        db_debug("more_results:".(defined($more_results)?$more_results:''));
        if ( $more_results ) {
            db_debug("db_format_results: more_results:true");
        } else {
            db_debug("db_format_results: more_results:false");
        }
    }

    # db_echo(Dumper($sth));
    $sth->finish;

    @result_headers       = @headers;
    @result_set           = @table;
    @result_col_length    = @col_length;
    $result_max_col_width = $max_col_width;

    db_debug("db_format_results H:".Dumper(@result_headers));
    db_debug('db_format_results:R count:'.length(@result_set));
    db_debug("db_format_results R:".Dumper(@result_set));
    db_format_array();

    # Setting the dbext_dbi_result variable to DBI: instructs
    # dbext.vim to call db_print_results() to add the results
    # to the results buffer.
    my $result   = "DBI:";
    if ( defined($result) ) {
        db_debug("db_format_results:Setting result to:$result");
        db_set_vim_var('g:dbext_dbi_result', $result);
    } else {
        db_debug("db_format_results:returning -1");
        db_set_vim_var('g:dbext_dbi_result', -1);
        return -1;
    }

    db_debug("db_format_results:returning 0");
    return 0;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_format_array');
sub db_format_array()
{
    # For each row returned concatenate the columns together
    my $result   = "DBI:";
    my $fragment = "";
    my $i;
    my $val;
    db_debug( "db_format_array:".$result );
    $result = $result . db_vim_eval('g:dbext_dbi_msg');
    db_debug( "db_format_array: Finished with dbext_dbi_msg:".length($result) );
    # print Dumper( @result_set);
    db_debug( "db_format_array: printing result" );
    db_debug( "db_format_array:".$result );
    db_debug( "db_format_array: finished result" );
    foreach my $row2 ( @result_set ) {
        $i = 0;
        db_debug( "db_format_array: i:$i" );
        $fragment = "";
        # Ensure each column is the maximum width for the column by
        # blank padding each string.
        # Add an additional 3 spaces between columns.
        foreach my $col2 ( @{$row2} ) {
            $val = (defined($col2)?$col2:"NULL");
            # Remove any unprintable characters 
            $val =~ tr/\x80-\xFF/ /d;
            # Remove the NULL character since Vim will treat this as 
            # the end of the line
            # For more of these see:
            #    http://www.asciitable.com/
            $val =~ tr/\x00/ /d;
            $fragment = substr ($val.(' ' x $result_col_length[$i]), 0, $result_col_length[$i]);
            $col2 = $fragment;
            $i++;
        }
        # Finally, escape any double quotes with a preceeding slash
        # $result = db_escape($result) . "\n";
        # RIGHT HERE, SOMETHING WITHT THE ESCAPE
        $result = $result . "\n";
    }
    db_debug('db_format_array:result_set:'.Dumper(@result_set));

    return 0;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_print_results');
sub db_print_results 
{
    my $format = shift;
    my $last_line = db_vim_op("Count");
    my $row_count = 0;
    my $i = 0;
    my $line = "";
    my $fragment = "";
    my $col_name = "";

    if ( ! defined($format) ) {
        $format = "horizontal";
    }
    db_debug("db_print_results: $format");

    my $msg = db_vim_eval('g:dbext_dbi_msg');
    if ( ! $msg eq "" ) {
        db_debug("db_print_results: Adding msg to output: $msg");
        db_vim_print($last_line, $msg);
        $msg    = "";
        $last_line = db_vim_op("Count");
    }
    db_set_vim_var('g:dbext_dbi_msg', '');

    db_debug("db_print_results: Using format: $format");
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
        db_debug("db_print_results: Horizontal, looping for col_length");
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
        db_debug("db_print_results: Vertical, looping for col_length");
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
    db_debug("db_print_results: returning 0");
    return 0;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_results_variable');
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

    my $msg = db_vim_eval('g:dbext_dbi_msg');
    if ( ! $msg eq "" ) {
        $result .= db_escape($msg)."\n";
    }
    db_set_vim_var('g:dbext_dbi_msg', '');

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
        db_set_vim_var('g:dbext_dbi_result', $result);
    } else {
        db_set_vim_var('g:dbext_dbi_result', -1);
        return -1;
    }

    return 0;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_results_list');
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

    db_set_vim_var('g:dbext_dbi_result', '[]');
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
                # VIM::DoCommand($line);
                db_vim_op("call", $line);
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
            # VIM::DoCommand($line);
            db_vim_op("call", $line);
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

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_catalogue');
sub db_catalogue 
{
    my $request_type = shift;
    my $result       = undef;
    my $object_type  = undef;
    my $catalogue    = undef;
    my $schema       = undef;
    my $table        = undef;
    my $column       = '%';
    my $level;
    my $err;
    my $msg;
    my $state;
    my $conn_local;
    my $driver;

    # $debug         = db_is_debug();
    if ( length($request_type) == 0 ) {
        db_set_vim_var('g:dbext_dbi_msg', 'A request_type must be specified');
        db_set_vim_var('g:dbext_dbi_result', -1);
        return -1;
    }
    if ( ! db_is_connected() ) {
        db_debug("You must connect first");
        db_set_vim_var('g:dbext_dbi_msg', 'You are not connected to a database');
        db_set_vim_var('g:dbext_dbi_result', -1);
        return -1;
    }

    ($conn_local, $driver) = db_get_connection();
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
        db_set_vim_var('g:dbext_dbi_msg', 'Invalid statement for request type:'.$request_type.":".db_escape($@));
        db_set_vim_var('g:dbext_dbi_result', -1);
        return -1;
    }
    if ( defined($sth) ) {
        db_debug("db_catalogue statement is defined");
        $sth->execute;
        ( $level, $err, $msg, $state ) = db_check_error($driver);
        if ( ! $msg eq "" ) {
            $msg = "$level. DBcate:".(($level ne "I")?"SQLCode:$err:":"").$msg.(($state ne "")?":$state":"");
            db_set_vim_var('g:dbext_dbi_msg', $msg);
            if ( $level eq "E" ) {
                db_set_vim_var('g:dbext_dbi_result', -1);
                db_debug("db_catalogue:$msg - exiting");
                return -1;
            }
        }
        db_format_results( $sth );
    } else {
        db_set_vim_var('g:dbext_dbi_result', -1);
        ( $level, $err, $msg, $state ) = db_check_error($driver);
        if ( ! $msg eq "" ) {
            $msg = "$level. DBcats:".(($level ne "I")?"SQLCode:$err:":"").$msg.(($state ne "")?":$state":"");
            db_set_vim_var('g:dbext_dbi_msg', $msg);
            if ( $level eq "E" ) {
                db_set_vim_var('g:dbext_dbi_result', -1);
                db_debug("db_catalogue:$msg - exiting");
                return -1;
            }
        }
        db_debug("db_catalogue statement failed:".$DBI::err.":".db_escape($DBI::errstr));
        return -1;
    }

    return 0;
}

db_set_vim_var('g:loaded_dbext_dbi_msg', 'db_odbc_catalogue');
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
    my $driver;

    # $debug         = db_is_debug();
    if ( length($request_type) == 0 ) {
        db_debug("db_odbc_catalogue: A request type must be specified");
        db_set_vim_var('g:dbext_dbi_msg', 'A request_type must be specified');
        db_set_vim_var('g:dbext_dbi_result', -1);
        return -1;
    }
    if ( ! db_is_connected() ) {
        db_debug("db_odbc_catalogue: You are not connected to a database");
        db_set_vim_var('g:dbext_dbi_msg', 'You are not connected to a database');
        db_set_vim_var('g:dbext_dbi_result', -1);
        return -1;
    }

    ($conn_local, $driver) = db_get_connection();
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
        db_set_vim_var('g:dbext_dbi_msg', 'Invalid statement for request type:'.$request_type.":".db_escape($@));
        db_set_vim_var('g:dbext_dbi_result', -1);
        return -1;
    }
    if ( defined($sth) ) {
        db_debug("db_odbc_catalogue statement is defined");
        # Do not execute the statement when calling the func() method
        # http://www.mail-archive.com/dbi-users@perl.org/msg17977.html
        # $sth->execute;
        db_format_results( $sth );
    } else {
        db_set_vim_var('g:dbext_dbi_result', -1);
        my ( $level, $err, $msg, $state ) = db_check_error($driver);
        if ( ! $msg eq "" ) {
            $msg = "$level. DBOcat:".(($level ne "I")?"SQLCode:$err:":"").$msg.(($state ne "")?":$state":"");
            db_set_vim_var('g:dbext_dbi_msg', $msg);
            if ( $level eq "E" ) {
                db_set_vim_var('g:dbext_dbi_result', -1);
                db_debug("db_odbc_catalogue:$msg - exiting");
                return -1;
            }
        }
        return -1;
    }


    return 0;
}
db_get_defaults();
db_set_vim_var('g:loaded_dbext_dbi_msg', 'Perl subroutines ready');
db_set_vim_var('result', '');
db_vim_check_inside();
db_set_vim_var('g:dbext_dbi_inside', $inside_vim);

EOCore

    " echomsg "Finished loading Perl subroutines"
    let g:dbext_dbi_loaded_perl_subs = 1
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

" vim:fdm=marker:nowrap:ts=4:expandtab:
