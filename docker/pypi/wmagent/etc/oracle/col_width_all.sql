-- An auxiliary file to help build automatic columns formatting by estimating the column width
-- based on the average data length populated in the table.
-- Inspired by: https://www.dbi-services.com/blog/automatic-column-formatting-in-oracle-sqlplus/

set termout off heading off trimspool on feed off timing off verify off
SET SERVEROUTPUT ON
define col_width_path='&oracle_tmp_path./&owner./col_width.sql'
spool &col_width_path
declare
  cmd varchar2(2048);
  col_width number;
begin
  for i in (select column_name,avg_col_len,data_length from all_tab_columns
             where owner='&owner'
               and data_type in ('VARCHAR2','NVARCHAR2')
               -- avoid formatting column headers common between tables but having different data_types
               and column_name not in (
                 select column_name from all_tab_columns
                  where owner='&owner'
                    and data_type not in ('VARCHAR2','NVARCHAR2'))) loop
    select max(avg_col_len) into col_width from all_tab_columns where owner='&owner' and column_name=i.column_name;
    if col_width = 0 then
      col_width := 1;
    else
      col_width := ceil(col_width*1.2);
    end if;
    cmd := 'column '||i.column_name||' format a'||col_width;
    dbms_output.put_line(cmd);
  end loop;
end;
/
spool off
@@&col_width_path
set termout on heading on feed on timing on verify on
