SELECT
  owner,
  name AS index_name,
  total_access_count,
  total_exec_count,
  total_rows_returned,
  last_used
FROM dba_index_usage
where owner='SCHEMANAME' and name like '%name%'
ORDER BY  last_used desc;
