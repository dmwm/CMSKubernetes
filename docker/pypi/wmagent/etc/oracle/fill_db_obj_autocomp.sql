-- An auxiliary file for fetching all database objects accessible to the current user and populate
-- them in a predefined file, in order to be later used as an auto completion dictionary.

set termout off heading off trimspool on feed off timing off verify off
SET SERVEROUTPUT ON
spool &db_obj_autocomp
select table_name from all_tables where owner='&owner';
select column_name from all_tab_columns where owner='&owner';
spool off
set termout on heading on feed on timing on verify on
