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
SET WRAP OFF
SET UNDERLINE =
SET PAUSE text
SET PAUSE ON
SET NUMWIDTH 10
SET LINESIZE WINDOW
SET HISTORY ON
SET FEEDBACK ON
SET COLSEP |
SET TAB OFF
SET TRIMOUT ON
SET RECSEP WRAPPED
SET RECSEPCHAR "-"
SET LONG 16
COLUMN CHAR FORMAT     A16
COLUMN VARCHAR FORMAT  A16
COLUMN NCHAR FORMAT    A16
COLUMN NVARCHAR FORMAT A16
