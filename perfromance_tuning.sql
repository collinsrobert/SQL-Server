--check blocking #######################################################################################################################################


WITH profiled_sessions as (
	SELECT DISTINCT session_id profiled_session_id from sys.dm_exec_query_profiles
)
SELECT 
   [Session ID]    = s.session_id, 
   [User Process]  = CONVERT(CHAR(1), s.is_user_process),
   [Login]         = s.login_name,   
   [Database]      = case when p.dbid=0 then N'' else ISNULL(db_name(p.dbid),N'') end, 
   [Task State]    = ISNULL(t.task_state, N''), 
   [Command]       = ISNULL(r.command, N''), 
   [Application]   = ISNULL(s.program_name, N''), 
   [Wait Time (ms)]     = ISNULL(w.wait_duration_ms, 0),
   [Wait Type]     = ISNULL(w.wait_type, N''),
   [Wait Resource] = ISNULL(w.resource_description, N''), 
   [Blocked By]    = ISNULL(CONVERT (varchar, w.blocking_session_id), ''),
   [Head Blocker]  = 
        CASE 
            -- session has an active request, is blocked, but is blocking others or session is idle but has an open tran and is blocking others
            WHEN r2.session_id IS NOT NULL AND (r.blocking_session_id = 0 OR r.session_id IS NULL) THEN '1' 
            -- session is either not blocking someone, or is blocking someone but is blocked by another party
            ELSE ''
        END, 
   [Total CPU (ms)] = s.cpu_time, 
   [Total Physical I/O (MB)]   = (s.reads + s.writes) * 8 / 1024, 
   [Memory Use (KB)]  = s.memory_usage * (8192 / 1024), 
   [Open Transactions] = ISNULL(r.open_transaction_count,0), 
   [Login Time]    = s.login_time, 
   [Last Request Start Time] = s.last_request_start_time,
   [Host Name]     = ISNULL(s.host_name, N''),
   [Net Address]   = ISNULL(c.client_net_address, N''), 
   [Execution Context ID] = ISNULL(t.exec_context_id, 0),
   [Request ID] = ISNULL(r.request_id, 0),
   [Workload Group] = ISNULL(g.name, N''),
   [Profiled Session Id] = profiled_session_id
FROM sys.dm_exec_sessions s LEFT OUTER JOIN sys.dm_exec_connections c ON (s.session_id = c.session_id)
LEFT OUTER JOIN sys.dm_exec_requests r ON (s.session_id = r.session_id)
LEFT OUTER JOIN sys.dm_os_tasks t ON (r.session_id = t.session_id AND r.request_id = t.request_id)
LEFT OUTER JOIN 
(
    -- In some cases (e.g. parallel queries, also waiting for a worker), one thread can be flagged as 
    -- waiting for several different threads.  This will cause that thread to show up in multiple rows 
    -- in our grid, which we don't want.  Use ROW_NUMBER to select the longest wait for each thread, 
    -- and use it as representative of the other wait relationships this thread is involved in. 
    SELECT *, ROW_NUMBER() OVER (PARTITION BY waiting_task_address ORDER BY wait_duration_ms DESC) AS row_num
    FROM sys.dm_os_waiting_tasks 
) w ON (t.task_address = w.waiting_task_address) AND w.row_num = 1
LEFT OUTER JOIN sys.dm_exec_requests r2 ON (s.session_id = r2.blocking_session_id)
LEFT OUTER JOIN sys.dm_resource_governor_workload_groups g ON (g.group_id = s.group_id)
LEFT OUTER JOIN sys.sysprocesses p ON (s.session_id = p.spid)
LEFT OUTER JOIN profiled_sessions ON profiled_session_id = s.session_id
ORDER BY s.session_id;

--check waits ########################################################################################################################


---TOP SQL Queries ############################################################################################################
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



--USER Sessions #########################################################################################################################################

exec sp_executesql @stmt=N'select session_id,
		login_name,
		host_name,
		program_name,
		nt_domain,
		nt_user_name,
		status,
		cpu_time,
		memory_usage,
		last_request_start_time,
		last_request_end_time,
		logical_reads,
		reads,
		writes,
		is_user_process
	from sys.dm_exec_sessions s
	WHERE s.is_user_process = CASE when @include_system_processes > 0 THEN s.is_user_process ELSE 1 END
',@params=N'@include_system_processes Bit',@include_system_processes=0


----Current Activity USER REQUESTS #########################################################################################################


 select count(r.request_id) as num_requests,
		sum(convert(bigint, r.total_elapsed_time)) as total_elapsed_time,
		sum(convert(bigint, r.cpu_time)) as cpu_time,
		case when sum(convert(bigint, r.total_elapsed_time)) - sum(convert(bigint, r.cpu_time)) > 0
			then sum(convert(bigint, r.total_elapsed_time)) - sum(convert(bigint, r.cpu_time))
			else 0
		end as wait_time,
		case when sum(r.logical_reads) > 0 then (sum(r.logical_reads) - isnull(sum(r.reads), 0)) / convert(float, sum(r.logical_reads))
			else NULL
			end as cache_hit_ratio
	from sys.dm_exec_requests r
		join sys.dm_exec_sessions s on r.session_id = s.session_id
	where s.is_user_process = 0x1 

----Current Activity USER Sessions #########################################################################################################
 select count(*) as num_sessions,
		sum(convert(bigint, s.total_elapsed_time)) as total_elapsed_time,
		sum(convert(bigint, s.cpu_time)) as cpu_time, 
		case when sum(convert(bigint, s.total_elapsed_time)) - sum(convert(bigint, s.cpu_time)) > 0
			then sum(convert(bigint, s.total_elapsed_time)) - sum(convert(bigint, s.cpu_time))
			else 0
		end as wait_time,
		sum(convert(bigint, (datediff(dd, login_time, getdate()) * cast(86400000 as bigint) + datediff(ms, dateadd(dd, datediff(dd, login_time, getdate()), login_time), getdate())))) - sum(convert(bigint, s.total_elapsed_time)) as idle_connection_time,
   case when sum(s.logical_reads) > 0 then (sum(s.logical_reads) - isnull(sum(s.reads), 0)) / convert(float, sum(s.logical_reads))
			else NULL
			end as cache_hit_ratio
	from sys.dm_exec_sessions s
	where s.is_user_process = 0x1 


----TOP QUERIES BY PHYSICAL READS #########################################################################################################

exec sp_executesql @stmt=N'SELECT 
	text as query_text, 
	master.dbo.fn_varbintohexstr(query_hash) as  query_hash, 
	master.dbo.fn_varbintohexstr(sql_handle) as sql_handle,
	statement_start_offset,
	statement_end_offset,
	querycount, 
	queryplanhashcount, 
	execution_count,
	total_elapsed_time,
	min_elapsed_time, 
	max_elapsed_time,
	average_elapsed_time,
	total_CPU_time, 
	min_CPU_time, 
	max_CPU_time, 
	average_CPU_time,
	total_logical_reads, 
	min_logical_reads, 
	max_logical_reads, 
	average_logical_reads,
	total_physical_reads, 
	min_physical_reads, 
	max_physical_reads, 
	average_physical_reads, 
	total_logical_writes, 
	min_logical_writes, 
	max_logical_writes, 
	average_logical_writes,
	total_clr_time, 
	min_clr_time, 
	max_clr_time, 
	average_clr_time,
	max_plan_generation_num,
	earliest_creation_time,
	query_rank,
	charted_value,
	master.dbo.fn_varbintohexstr(plan_handle) as plan_handle
	FROM   (SELECT s.*, 
				   Row_number() OVER(ORDER BY charted_value DESC) AS query_rank 
			FROM   (SELECT CASE @OrderBy_Criteria 
							 WHEN ''Logical Reads'' THEN SUM(total_logical_reads) 
							 WHEN ''Physical Reads'' THEN SUM(total_physical_reads) 
							 WHEN ''Logical Writes'' THEN SUM(total_logical_writes) 
							 WHEN ''CPU'' THEN SUM(total_worker_time) / 1000 
							 WHEN ''Duration'' THEN SUM(total_elapsed_time) / 1000 
							 WHEN ''CLR Time'' THEN SUM(total_clr_time) / 1000 
						   END AS charted_value, 
					   query_hash, 
					   MAX(sql_handle_1)				sql_handle, 
					   MAX(statement_start_offset_1)    statement_start_offset, 
					   MAX(statement_end_offset_1)      statement_end_offset, 
					   COUNT(*)							querycount, 
					   COUNT (DISTINCT query_plan_hash) queryplanhashcount, 
					   MAX(plan_handle_1)			plan_handle,
					   MIN(creation_time)				earliest_creation_time,
                 
					   SUM(execution_count)             execution_count, 
					   SUM(total_elapsed_time)          total_elapsed_time, 
					   min(min_elapsed_time)            min_elapsed_time, 
					   max(max_elapsed_time)            max_elapsed_time,
					   SUM(total_elapsed_time)/SUM(execution_count) average_elapsed_time, 
                       
					   SUM(total_worker_time)           total_CPU_time, 
					   min(min_worker_time)             min_CPU_time, 
					   max(max_worker_time)            max_CPU_time, 
					   SUM(total_worker_time)/SUM(execution_count) average_CPU_time, 

                       SUM(total_logical_reads)         total_logical_reads, 
                       min(min_logical_reads)           min_logical_reads, 
                       max(max_logical_reads)           max_logical_reads, 
                       SUM(total_logical_reads)/SUM(execution_count) average_logical_reads, 
                       
                       SUM(total_physical_reads)        total_physical_reads, 
                       min(min_physical_reads)         min_physical_reads, 
                       max(max_physical_reads)          max_physical_reads, 
                       SUM(total_physical_reads)/SUM(execution_count) average_physical_reads, 
                       
                       SUM(total_logical_writes)        total_logical_writes, 
                 
                       min(min_logical_writes)          min_logical_writes, 
                       max(max_logical_writes)          max_logical_writes, 
                       SUM(total_logical_writes)/SUM(execution_count) average_logical_writes, 
                       
                       SUM(total_clr_time)              total_clr_time, 
                       SUM(total_clr_time)/SUM(execution_count) average_clr_time, 
                       min(min_clr_time)                min_clr_time, 
                       max(max_clr_time)                max_clr_time, 
                       
                       MAX(plan_generation_num)         max_plan_generation_num
                FROM (
					-- Implement my own FIRST aggregate to get consistent values for sql_handle, start/end offsets of 
					-- an arbitrary first row for a given query_hash
                    SELECT 
						CASE when t.rownum = 1 THEN plan_handle ELSE NULL END as plan_handle_1,
						CASE WHEN t.rownum = 1 THEN sql_handle ELSE NULL END AS sql_handle_1, 
						CASE WHEN t.rownum = 1 THEN statement_start_offset ELSE NULL END AS statement_start_offset_1, 
						CASE WHEN t.rownum = 1 THEN statement_end_offset ELSE NULL END AS statement_end_offset_1, 
						* 
					FROM   (SELECT row_number() OVER (PARTITION BY query_hash ORDER BY sql_handle) AS rownum, * 
							FROM   sys.dm_exec_query_stats) AS t) AS t2 
					GROUP  BY query_hash
               ) AS s 
			WHERE  s.charted_value > 0
        ) AS qs
         
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt  
	where query_rank <= 20
	order by charted_value desc

',@params=N'@OrderBy_Criteria NVarChar(max)',@OrderBy_Criteria=N'Physical Reads'




----TOP QUERIES BY LOGICALE WRITES #########################################################################################################
exec sp_executesql @stmt=N'SELECT 
	text as query_text, 
	master.dbo.fn_varbintohexstr(query_hash) as  query_hash, 
	master.dbo.fn_varbintohexstr(sql_handle) as sql_handle,
	statement_start_offset,
	statement_end_offset,
	querycount, 
	queryplanhashcount, 
	execution_count,
	total_elapsed_time,
	min_elapsed_time, 
	max_elapsed_time,
	average_elapsed_time,
	total_CPU_time, 
	min_CPU_time, 
	max_CPU_time, 
	average_CPU_time,
	total_logical_reads, 
	min_logical_reads, 
	max_logical_reads, 
	average_logical_reads,
	total_physical_reads, 
	min_physical_reads, 
	max_physical_reads, 
	average_physical_reads, 
	total_logical_writes, 
	min_logical_writes, 
	max_logical_writes, 
	average_logical_writes,
	total_clr_time, 
	min_clr_time, 
	max_clr_time, 
	average_clr_time,
	max_plan_generation_num,
	earliest_creation_time,
	query_rank,
	charted_value,
	master.dbo.fn_varbintohexstr(plan_handle) as plan_handle
	FROM   (SELECT s.*, 
				   Row_number() OVER(ORDER BY charted_value DESC) AS query_rank 
			FROM   (SELECT CASE @OrderBy_Criteria 
							 WHEN ''Logical Reads'' THEN SUM(total_logical_reads) 
							 WHEN ''Physical Reads'' THEN SUM(total_physical_reads) 
							 WHEN ''Logical Writes'' THEN SUM(total_logical_writes) 
							 WHEN ''CPU'' THEN SUM(total_worker_time) / 1000 
							 WHEN ''Duration'' THEN SUM(total_elapsed_time) / 1000 
							 WHEN ''CLR Time'' THEN SUM(total_clr_time) / 1000 
						   END AS charted_value, 
					   query_hash, 
					   MAX(sql_handle_1)				sql_handle, 
					   MAX(statement_start_offset_1)    statement_start_offset, 
					   MAX(statement_end_offset_1)      statement_end_offset, 
					   COUNT(*)							querycount, 
					   COUNT (DISTINCT query_plan_hash) queryplanhashcount, 
					   MAX(plan_handle_1)			plan_handle,
					   MIN(creation_time)				earliest_creation_time,
                 
					   SUM(execution_count)             execution_count, 
					   SUM(total_elapsed_time)          total_elapsed_time, 
					   min(min_elapsed_time)            min_elapsed_time, 
					   max(max_elapsed_time)            max_elapsed_time,
					   SUM(total_elapsed_time)/SUM(execution_count) average_elapsed_time, 
                       
					   SUM(total_worker_time)           total_CPU_time, 
					   min(min_worker_time)             min_CPU_time, 
					   max(max_worker_time)            max_CPU_time, 
					   SUM(total_worker_time)/SUM(execution_count) average_CPU_time, 

                       SUM(total_logical_reads)         total_logical_reads, 
                       min(min_logical_reads)           min_logical_reads, 
                       max(max_logical_reads)           max_logical_reads, 
                       SUM(total_logical_reads)/SUM(execution_count) average_logical_reads, 
                       
                       SUM(total_physical_reads)        total_physical_reads, 
                       min(min_physical_reads)         min_physical_reads, 
                       max(max_physical_reads)          max_physical_reads, 
                       SUM(total_physical_reads)/SUM(execution_count) average_physical_reads, 
                       
                       SUM(total_logical_writes)        total_logical_writes, 
                 
                       min(min_logical_writes)          min_logical_writes, 
                       max(max_logical_writes)          max_logical_writes, 
                       SUM(total_logical_writes)/SUM(execution_count) average_logical_writes, 
                       
                       SUM(total_clr_time)              total_clr_time, 
                       SUM(total_clr_time)/SUM(execution_count) average_clr_time, 
                       min(min_clr_time)                min_clr_time, 
                       max(max_clr_time)                max_clr_time, 
                       
                       MAX(plan_generation_num)         max_plan_generation_num
                FROM (
					-- Implement my own FIRST aggregate to get consistent values for sql_handle, start/end offsets of 
					-- an arbitrary first row for a given query_hash
                    SELECT 
						CASE when t.rownum = 1 THEN plan_handle ELSE NULL END as plan_handle_1,
						CASE WHEN t.rownum = 1 THEN sql_handle ELSE NULL END AS sql_handle_1, 
						CASE WHEN t.rownum = 1 THEN statement_start_offset ELSE NULL END AS statement_start_offset_1, 
						CASE WHEN t.rownum = 1 THEN statement_end_offset ELSE NULL END AS statement_end_offset_1, 
						* 
					FROM   (SELECT row_number() OVER (PARTITION BY query_hash ORDER BY sql_handle) AS rownum, * 
							FROM   sys.dm_exec_query_stats) AS t) AS t2 
					GROUP  BY query_hash
               ) AS s 
			WHERE  s.charted_value > 0
        ) AS qs
         
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt  
	where query_rank <= 20
	order by charted_value desc

',@params=N'@OrderBy_Criteria NVarChar(max)',@OrderBy_Criteria=N'Logical Writes'

----TOP QUERIES BY DURATION #########################################################################################################


exec sp_executesql @stmt=N'SELECT 
	text as query_text, 
	master.dbo.fn_varbintohexstr(query_hash) as  query_hash, 
	master.dbo.fn_varbintohexstr(sql_handle) as sql_handle,
	statement_start_offset,
	statement_end_offset,
	querycount, 
	queryplanhashcount, 
	execution_count,
	total_elapsed_time,
	min_elapsed_time, 
	max_elapsed_time,
	average_elapsed_time,
	total_CPU_time, 
	min_CPU_time, 
	max_CPU_time, 
	average_CPU_time,
	total_logical_reads, 
	min_logical_reads, 
	max_logical_reads, 
	average_logical_reads,
	total_physical_reads, 
	min_physical_reads, 
	max_physical_reads, 
	average_physical_reads, 
	total_logical_writes, 
	min_logical_writes, 
	max_logical_writes, 
	average_logical_writes,
	total_clr_time, 
	min_clr_time, 
	max_clr_time, 
	average_clr_time,
	max_plan_generation_num,
	earliest_creation_time,
	query_rank,
	charted_value,
	master.dbo.fn_varbintohexstr(plan_handle) as plan_handle
	FROM   (SELECT s.*, 
				   Row_number() OVER(ORDER BY charted_value DESC) AS query_rank 
			FROM   (SELECT CASE @OrderBy_Criteria 
							 WHEN ''Logical Reads'' THEN SUM(total_logical_reads) 
							 WHEN ''Physical Reads'' THEN SUM(total_physical_reads) 
							 WHEN ''Logical Writes'' THEN SUM(total_logical_writes) 
							 WHEN ''CPU'' THEN SUM(total_worker_time) / 1000 
							 WHEN ''Duration'' THEN SUM(total_elapsed_time) / 1000 
							 WHEN ''CLR Time'' THEN SUM(total_clr_time) / 1000 
						   END AS charted_value, 
					   query_hash, 
					   MAX(sql_handle_1)				sql_handle, 
					   MAX(statement_start_offset_1)    statement_start_offset, 
					   MAX(statement_end_offset_1)      statement_end_offset, 
					   COUNT(*)							querycount, 
					   COUNT (DISTINCT query_plan_hash) queryplanhashcount, 
					   MAX(plan_handle_1)			plan_handle,
					   MIN(creation_time)				earliest_creation_time,
                 
					   SUM(execution_count)             execution_count, 
					   SUM(total_elapsed_time)          total_elapsed_time, 
					   min(min_elapsed_time)            min_elapsed_time, 
					   max(max_elapsed_time)            max_elapsed_time,
					   SUM(total_elapsed_time)/SUM(execution_count) average_elapsed_time, 
                       
					   SUM(total_worker_time)           total_CPU_time, 
					   min(min_worker_time)             min_CPU_time, 
					   max(max_worker_time)            max_CPU_time, 
					   SUM(total_worker_time)/SUM(execution_count) average_CPU_time, 

                       SUM(total_logical_reads)         total_logical_reads, 
                       min(min_logical_reads)           min_logical_reads, 
                       max(max_logical_reads)           max_logical_reads, 
                       SUM(total_logical_reads)/SUM(execution_count) average_logical_reads, 
                       
                       SUM(total_physical_reads)        total_physical_reads, 
                       min(min_physical_reads)         min_physical_reads, 
                       max(max_physical_reads)          max_physical_reads, 
                       SUM(total_physical_reads)/SUM(execution_count) average_physical_reads, 
                       
                       SUM(total_logical_writes)        total_logical_writes, 
                 
                       min(min_logical_writes)          min_logical_writes, 
                       max(max_logical_writes)          max_logical_writes, 
                       SUM(total_logical_writes)/SUM(execution_count) average_logical_writes, 
                       
                       SUM(total_clr_time)              total_clr_time, 
                       SUM(total_clr_time)/SUM(execution_count) average_clr_time, 
                       min(min_clr_time)                min_clr_time, 
                       max(max_clr_time)                max_clr_time, 
                       
                       MAX(plan_generation_num)         max_plan_generation_num
                FROM (
					-- Implement my own FIRST aggregate to get consistent values for sql_handle, start/end offsets of 
					-- an arbitrary first row for a given query_hash
                    SELECT 
						CASE when t.rownum = 1 THEN plan_handle ELSE NULL END as plan_handle_1,
						CASE WHEN t.rownum = 1 THEN sql_handle ELSE NULL END AS sql_handle_1, 
						CASE WHEN t.rownum = 1 THEN statement_start_offset ELSE NULL END AS statement_start_offset_1, 
						CASE WHEN t.rownum = 1 THEN statement_end_offset ELSE NULL END AS statement_end_offset_1, 
						* 
					FROM   (SELECT row_number() OVER (PARTITION BY query_hash ORDER BY sql_handle) AS rownum, * 
							FROM   sys.dm_exec_query_stats) AS t) AS t2 
					GROUP  BY query_hash
               ) AS s 
			WHERE  s.charted_value > 0
        ) AS qs
         
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt  
	where query_rank <= 20
	order by charted_value desc

',@params=N'@OrderBy_Criteria NVarChar(max)',@OrderBy_Criteria=N'Duration'



-----------------------------------TOP BY CPU ##################################################################################################

exec sp_executesql @stmt=N'SELECT 
	text as query_text, 
	master.dbo.fn_varbintohexstr(query_hash) as  query_hash, 
	master.dbo.fn_varbintohexstr(sql_handle) as sql_handle,
	statement_start_offset,
	statement_end_offset,
	querycount, 
	queryplanhashcount, 
	execution_count,
	total_elapsed_time,
	min_elapsed_time, 
	max_elapsed_time,
	average_elapsed_time,
	total_CPU_time, 
	min_CPU_time, 
	max_CPU_time, 
	average_CPU_time,
	total_logical_reads, 
	min_logical_reads, 
	max_logical_reads, 
	average_logical_reads,
	total_physical_reads, 
	min_physical_reads, 
	max_physical_reads, 
	average_physical_reads, 
	total_logical_writes, 
	min_logical_writes, 
	max_logical_writes, 
	average_logical_writes,
	total_clr_time, 
	min_clr_time, 
	max_clr_time, 
	average_clr_time,
	max_plan_generation_num,
	earliest_creation_time,
	query_rank,
	charted_value,
	master.dbo.fn_varbintohexstr(plan_handle) as plan_handle
	FROM   (SELECT s.*, 
				   Row_number() OVER(ORDER BY charted_value DESC) AS query_rank 
			FROM   (SELECT CASE @OrderBy_Criteria 
							 WHEN ''Logical Reads'' THEN SUM(total_logical_reads) 
							 WHEN ''Physical Reads'' THEN SUM(total_physical_reads) 
							 WHEN ''Logical Writes'' THEN SUM(total_logical_writes) 
							 WHEN ''CPU'' THEN SUM(total_worker_time) / 1000 
							 WHEN ''Duration'' THEN SUM(total_elapsed_time) / 1000 
							 WHEN ''CLR Time'' THEN SUM(total_clr_time) / 1000 
						   END AS charted_value, 
					   query_hash, 
					   MAX(sql_handle_1)				sql_handle, 
					   MAX(statement_start_offset_1)    statement_start_offset, 
					   MAX(statement_end_offset_1)      statement_end_offset, 
					   COUNT(*)							querycount, 
					   COUNT (DISTINCT query_plan_hash) queryplanhashcount, 
					   MAX(plan_handle_1)			plan_handle,
					   MIN(creation_time)				earliest_creation_time,
                 
					   SUM(execution_count)             execution_count, 
					   SUM(total_elapsed_time)          total_elapsed_time, 
					   min(min_elapsed_time)            min_elapsed_time, 
					   max(max_elapsed_time)            max_elapsed_time,
					   SUM(total_elapsed_time)/SUM(execution_count) average_elapsed_time, 
                       
					   SUM(total_worker_time)           total_CPU_time, 
					   min(min_worker_time)             min_CPU_time, 
					   max(max_worker_time)            max_CPU_time, 
					   SUM(total_worker_time)/SUM(execution_count) average_CPU_time, 

                       SUM(total_logical_reads)         total_logical_reads, 
                       min(min_logical_reads)           min_logical_reads, 
                       max(max_logical_reads)           max_logical_reads, 
                       SUM(total_logical_reads)/SUM(execution_count) average_logical_reads, 
                       
                       SUM(total_physical_reads)        total_physical_reads, 
                       min(min_physical_reads)         min_physical_reads, 
                       max(max_physical_reads)          max_physical_reads, 
                       SUM(total_physical_reads)/SUM(execution_count) average_physical_reads, 
                       
                       SUM(total_logical_writes)        total_logical_writes, 
                 
                       min(min_logical_writes)          min_logical_writes, 
                       max(max_logical_writes)          max_logical_writes, 
                       SUM(total_logical_writes)/SUM(execution_count) average_logical_writes, 
                       
                       SUM(total_clr_time)              total_clr_time, 
                       SUM(total_clr_time)/SUM(execution_count) average_clr_time, 
                       min(min_clr_time)                min_clr_time, 
                       max(max_clr_time)                max_clr_time, 
                       
                       MAX(plan_generation_num)         max_plan_generation_num
                FROM (
					-- Implement my own FIRST aggregate to get consistent values for sql_handle, start/end offsets of 
					-- an arbitrary first row for a given query_hash
                    SELECT 
						CASE when t.rownum = 1 THEN plan_handle ELSE NULL END as plan_handle_1,
						CASE WHEN t.rownum = 1 THEN sql_handle ELSE NULL END AS sql_handle_1, 
						CASE WHEN t.rownum = 1 THEN statement_start_offset ELSE NULL END AS statement_start_offset_1, 
						CASE WHEN t.rownum = 1 THEN statement_end_offset ELSE NULL END AS statement_end_offset_1, 
						* 
					FROM   (SELECT row_number() OVER (PARTITION BY query_hash ORDER BY sql_handle) AS rownum, * 
							FROM   sys.dm_exec_query_stats) AS t) AS t2 
					GROUP  BY query_hash
               ) AS s 
			WHERE  s.charted_value > 0
        ) AS qs
         
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt  
	where query_rank <= 20
	order by charted_value desc

',@params=N'@OrderBy_Criteria NVarChar(max)',@OrderBy_Criteria=N'CPU'


------------------######TOP BY CLR Time #################################################################################################################

exec sp_executesql @stmt=N'SELECT 
	text as query_text, 
	master.dbo.fn_varbintohexstr(query_hash) as  query_hash, 
	master.dbo.fn_varbintohexstr(sql_handle) as sql_handle,
	statement_start_offset,
	statement_end_offset,
	querycount, 
	queryplanhashcount, 
	execution_count,
	total_elapsed_time,
	min_elapsed_time, 
	max_elapsed_time,
	average_elapsed_time,
	total_CPU_time, 
	min_CPU_time, 
	max_CPU_time, 
	average_CPU_time,
	total_logical_reads, 
	min_logical_reads, 
	max_logical_reads, 
	average_logical_reads,
	total_physical_reads, 
	min_physical_reads, 
	max_physical_reads, 
	average_physical_reads, 
	total_logical_writes, 
	min_logical_writes, 
	max_logical_writes, 
	average_logical_writes,
	total_clr_time, 
	min_clr_time, 
	max_clr_time, 
	average_clr_time,
	max_plan_generation_num,
	earliest_creation_time,
	query_rank,
	charted_value,
	master.dbo.fn_varbintohexstr(plan_handle) as plan_handle
	FROM   (SELECT s.*, 
				   Row_number() OVER(ORDER BY charted_value DESC) AS query_rank 
			FROM   (SELECT CASE @OrderBy_Criteria 
							 WHEN ''Logical Reads'' THEN SUM(total_logical_reads) 
							 WHEN ''Physical Reads'' THEN SUM(total_physical_reads) 
							 WHEN ''Logical Writes'' THEN SUM(total_logical_writes) 
							 WHEN ''CPU'' THEN SUM(total_worker_time) / 1000 
							 WHEN ''Duration'' THEN SUM(total_elapsed_time) / 1000 
							 WHEN ''CLR Time'' THEN SUM(total_clr_time) / 1000 
						   END AS charted_value, 
					   query_hash, 
					   MAX(sql_handle_1)				sql_handle, 
					   MAX(statement_start_offset_1)    statement_start_offset, 
					   MAX(statement_end_offset_1)      statement_end_offset, 
					   COUNT(*)							querycount, 
					   COUNT (DISTINCT query_plan_hash) queryplanhashcount, 
					   MAX(plan_handle_1)			plan_handle,
					   MIN(creation_time)				earliest_creation_time,
                 
					   SUM(execution_count)             execution_count, 
					   SUM(total_elapsed_time)          total_elapsed_time, 
					   min(min_elapsed_time)            min_elapsed_time, 
					   max(max_elapsed_time)            max_elapsed_time,
					   SUM(total_elapsed_time)/SUM(execution_count) average_elapsed_time, 
                       
					   SUM(total_worker_time)           total_CPU_time, 
					   min(min_worker_time)             min_CPU_time, 
					   max(max_worker_time)            max_CPU_time, 
					   SUM(total_worker_time)/SUM(execution_count) average_CPU_time, 

                       SUM(total_logical_reads)         total_logical_reads, 
                       min(min_logical_reads)           min_logical_reads, 
                       max(max_logical_reads)           max_logical_reads, 
                       SUM(total_logical_reads)/SUM(execution_count) average_logical_reads, 
                       
                       SUM(total_physical_reads)        total_physical_reads, 
                       min(min_physical_reads)         min_physical_reads, 
                       max(max_physical_reads)          max_physical_reads, 
                       SUM(total_physical_reads)/SUM(execution_count) average_physical_reads, 
                       
                       SUM(total_logical_writes)        total_logical_writes, 
                 
                       min(min_logical_writes)          min_logical_writes, 
                       max(max_logical_writes)          max_logical_writes, 
                       SUM(total_logical_writes)/SUM(execution_count) average_logical_writes, 
                       
                       SUM(total_clr_time)              total_clr_time, 
                       SUM(total_clr_time)/SUM(execution_count) average_clr_time, 
                       min(min_clr_time)                min_clr_time, 
                       max(max_clr_time)                max_clr_time, 
                       
                       MAX(plan_generation_num)         max_plan_generation_num
                FROM (
					-- Implement my own FIRST aggregate to get consistent values for sql_handle, start/end offsets of 
					-- an arbitrary first row for a given query_hash
                    SELECT 
						CASE when t.rownum = 1 THEN plan_handle ELSE NULL END as plan_handle_1,
						CASE WHEN t.rownum = 1 THEN sql_handle ELSE NULL END AS sql_handle_1, 
						CASE WHEN t.rownum = 1 THEN statement_start_offset ELSE NULL END AS statement_start_offset_1, 
						CASE WHEN t.rownum = 1 THEN statement_end_offset ELSE NULL END AS statement_end_offset_1, 
						* 
					FROM   (SELECT row_number() OVER (PARTITION BY query_hash ORDER BY sql_handle) AS rownum, * 
							FROM   sys.dm_exec_query_stats) AS t) AS t2 
					GROUP  BY query_hash
               ) AS s 
			WHERE  s.charted_value > 0
        ) AS qs
         
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt  
	where query_rank <= 20
	order by charted_value desc

',@params=N'@OrderBy_Criteria NVarChar(max)',@OrderBy_Criteria=N'CLR Time'

