
-- Use this script to find active expensive queiries


WITH profiled_sessions as (
	SELECT DISTINCT session_id profiled_session_id from sys.dm_exec_query_profiles
)
SELECT TOP 10 SUBSTRING(qt.TEXT, (er.statement_start_offset/2)+1,
((CASE er.statement_end_offset
WHEN -1 THEN DATALENGTH(qt.TEXT)
ELSE er.statement_end_offset
END - er.statement_start_offset)/2)+1) as [Query],
er.session_id as [Session Id],
er.cpu_time as [CPU (ms/sec)],
db.name as [Database Name],
er.total_elapsed_time as [Elapsed Time],
er.reads as [Reads],
er.writes as [Writes],
er.logical_reads as [Logical Reads],
er.row_count as [Row Count],
mg.granted_memory_kb as [Allocated Memory],
mg.used_memory_kb as [Used Memory],
mg.required_memory_kb as [Required Memory],
/* We must convert these to a hex string representation because they will be stored in a DataGridView, which can't handle binary cell values (assumes anything binary is an image) */
master.dbo.fn_varbintohexstr(er.plan_handle) AS [sample_plan_handle], 
er.statement_start_offset as [sample_statement_start_offset],
er.statement_end_offset as [sample_statement_end_offset],
profiled_session_id as [Profiled Session Id]
FROM 
sys.dm_exec_requests er
LEFT OUTER JOIN sys.dm_exec_query_memory_grants mg 
	ON er.session_id = mg.session_id
LEFT OUTER JOIN profiled_sessions
	ON profiled_session_id = er.session_id
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) qt,
sys.databases db
WHERE db.database_id = er.database_id
AND er.session_id  <> @@spid