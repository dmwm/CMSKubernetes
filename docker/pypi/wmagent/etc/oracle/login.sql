-- /*
-- https://docs.oracle.com/en/database/oracle/oracle-database/23/sqpug/SET-system-variable-summary.html
--
-- | SET WRAP {ON | OFF}                               | Controls whether to truncate the display of a selected row if it is too long for the current line width. OFF truncates                                                |
-- | SET UND[ERLINE] {- | c | ON | OFF}                | Sets the character used to underline column headings in reports.                                                                                                                                                                     |
-- | SET PAU[SE] {ON | OFF | text}                     | Enables you to control scrolling of your terminal when running reports.                                                                                               |
-- | SET PAGES[IZE] {14 | n}                           | Sets the number of lines in each page.                                                                                                                                |
-- | SET NUM[WIDTH] {10 | n}                           | Sets the default width for displaying numbers.                                                                                                                        |
-- | SET NUMF[ORMAT]                                   | format Sets the default format for displaying numbers.                                                                                                                |
-- | SET MARK[UP]                                      | Sets Outputs CSV format data or HTML marked up text.                                                                                                                  |
-- | SET LONG {80 | n}                                 | Sets maximum width (in bytes) for displaying LONG, BLOB, BFILE, CLOB, NCLOB and XMLType values; and for copying LONG values.                                          |
-- | SET LONGC[HUNKSIZE] {80 | n}                      | Sets the size (in bytes) of the increments in which SQL*Plus retrieves a LONG, BLOB, BFILE, CLOB, NCLOB or XMLType value.                                             |
-- | SET LOBOF[FSET] {1 | n}                           | Sets the starting position from which BLOB, BFILE, CLOB and NCLOB data is retrieved and displayed.                                                                    |
-- | SET JSONPRINT                                     | Formats the output of JSON type columns.                                                                                                                              |
-- | SET LIN[ESIZE] {80 | n | WINDOW}                  | Sets the total number of characters that SQL*Plus displays on one line before beginning a new line.                                                                   |
-- | SET FLU[SH] {ON | OFF}                            | Controls when output is sent to the user display device.                                                                                                              |
-- | SET HEA[DING] {ON | OFF}                          | Controls printing of column headings in reports.                                                                                                                      |
-- | SET HEADS[EP] {  | c | ON | OFF}                  | Defines the character you enter as the heading separator character.                                                                                                   |
-- | SET HIST[ORY] {ON | OFF | n}                      | Enables or disables the history of commands and SQL or PL/SQL statements issued in the current SQL*Plus session.                                                      |
-- | SET FEED[BACK] {6 | n | ON | OFF | ONLY}] [SQL_ID]| Displays the number of records returned by a query when a query selects at least n records.                                                                           |
-- | SET ESC[APE] {\ | c | ON | OFF}                   | Defines the character you enter as the escape character.                                                                                                              |
-- | SET ESCCHAR {@ | ? | % | OFF}                     | Specifies a special character to escape in a filename. Prevents character translation causing an error.                                                               |
-- | SET ERRORDETAILS { OFF | ON | VERBOSE }           | Displays the Oracle Database Error Help URL along with the error message cause and action details when any SQL, PL/SQL, or SQL*Plus statement fails during execution. |
-- | SET ECHO {ON | OFF}                               | Controls whether the START command lists each command in a script as the command is executed.                                                                         |
-- | SET COLSEP {  | text}                             | Sets the text to be printed between selected columns.                                                                                                                 |
-- | SET COLINVI[SIBLE] [ON | OFF]                     | ON sets the DESCRIBE command to display column information for an invisible column..                                                                                  |
-- | SET TRIMOUT ON                                    | Determines whether SQL*Plus puts trailing blanks at the end of each displayed line. ON removes blanks                                                                 |
-- */
--
-- SET WRAP OFF
-- SET UNDERLINE =
-- SET PAUSE text
-- SET PAUSE ON
-- SET NUMWIDTH 10
-- SET LINESIZE WINDOW
-- SET HISTORY ON
-- SET FEEDBACK ON
-- SET COLSEP |
-- SET TAB OFF
-- SET TRIMOUT ON
-- SET RECSEP WRAPPED
-- SET RECSEPCHAR "-"
-- SET LONG 16

set appinfo OFF
set appinfo "SQL*Plus"
set arraysize 15
set autocommit OFF
set autoprint OFF
set autorecovery OFF
set autotrace OFF
set blockterminator "."
set cmdsep OFF
set colinvisible OFF
set coljson OFF
set colsep " "
set compatibility NATIVE
set concat "."
set copycommit 0
set copytypecheck ON
set define "&"
set describe DEPTH 1 LINENUM OFF INDENT ON
set echo OFF
set editfile "afiedt.buf"
set embedded OFF
set escape OFF
set escchar OFF
set exitcommit ON
set feedback 6
set flagger OFF
set flush ON
set fullcolname OFF
set heading ON
set headsep "|"
-- set linesize 182
-- set linesize 2056
set linesize window
set lobprefetch 0
set logsource ""
set long 80
set longchunksize 80
set markup HTML OFF HEAD "<style type='text/css'> body {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} p {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} table,tr,td {font:10pt Arial,Helvetica,sans-serif; color:Black; background:#f7f7e7; padding:0px 0px 0px 0px; margin:0px 0px 0px 0px;} th {font:bold 10pt Arial,Helvetica,sans-serif; color:#336699; background:#cccc99; padding:0px 0px 0px 0px;} h1 {font:16pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;-
} h2 {font:bold 10pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; margin-top:4pt; margin-bottom:0pt;} a {font:9pt Arial,Helvetica,sans-serif; color:#663300; background:#ffffff; margin-top:0pt; margin-bottom:0pt; vertical-align:top;}</style><title>SQL*Plus Report</title>" BODY "" TABLE "border='1' width='90%' align='center' summary='Script output'" SPOOL OFF ENTMAP ON PRE OFF
set markup CSV OFF DELIMITER , QUOTE ON
set newpage 1
set null ""
set numformat ""
set numwidth 10
set pagesize 48
set pause OFF
set recsep WRAP
set recsepchar " "
set rowlimit OFF
set rowprefetch 1
set securedcol OFF
set serveroutput OFF
set shiftinout invisible
set showmode OFF
set sqlblanklines OFF
set sqlcase MIXED
set sqlcontinue "> "
set sqlnumber ON
set sqlpluscompatibility 19.0.0
set sqlprefix "#"
set sqlprompt "SQL> "
set sqlterminator ";"
set statementcache 0
set suffix "sql"
set tab ON
set termout ON
set time OFF
set timing OFF
set trimout ON
set trimspool OFF
set underline "="
set colsep "|"
set verify ON
--set wrap ON
set xmloptimizationcheck OFF

-- setup/run/define interactive db sessions related scripts and variables
-- define _editor=emacs
define owner=&1
define oracle_tmp_path=&2
define db_obj_autocomp=&3
@col_width_all
@fill_db_obj_autocomp
set editfile &oracle_tmp_path/afiedt.buf
