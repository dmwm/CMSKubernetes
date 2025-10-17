SET SERVEROUTPUT ON
set FEEDBACK OFF
declare
  print_line varchar2(2048);
begin
  for i in (select table_name, stale_stats from user_tab_statistics
             where (stale_stats is null)) loop
             -- refresh statistis for stale tables as well
             -- where stale_stats is null or stale_stats='YES') loop
    print_line:='Refreshing statistics for table: '||i.table_name;
    dbms_output.put_line(print_line);
    dbms_stats.gather_table_stats(ownname=>NULL, tabname=>i.table_name, cascade=>FALSE);
  end loop;
end;
/
