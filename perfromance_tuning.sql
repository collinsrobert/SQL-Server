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

--check waits and Wait types ########################################################################################################################

  

 
          SELECT
          r.session_id,
          (case
          when wait_type IN (N'BACKUPIO', N'BACKUPBUFFER') THEN 'Backup IO'
          when wait_type LIKE N'SE_REPL_%' or wait_type LIKE N'REPL_%'  or wait_type IN (N'REPLICA_WRITES', N'FCB_REPLICA_WRITE', N'FCB_REPLICA_READ', N'PWAIT_HADRSIM') THEN N'Replication'
          when wait_type IN (N'LOG_RATE_GOVERNOR', N'POOL_LOG_RATE_GOVERNOR', N'HADR_THROTTLE_LOG_RATE_GOVERNOR', N'INSTANCE_LOG_RATE_GOVERNOR') THEN N'Log Rate Governor'
          when wait_type = N'REPLICA_WRITE' THEN 'Snapshots'
          when wait_type = N'WAIT_XTP_OFFLINE_CKPT_LOG_IO' OR wait_type = N'WAIT_XTP_CKPT_CLOSE' THEN 'In-Memory OLTP Logging'
          when wait_type = N'SOS_SCHEDULER_YIELD' then N'CPU'
          when wait_type = N'THREADPOOL' then N'Worker Thread'
          when wait_type like N'LCK_M_%' then N'Lock'
          when wait_type like N'LATCH_%' then N'Latch'
          when wait_type like N'PAGELATCH_%' then N'Buffer Latch'
          when wait_type like N'PAGEIOLATCH_%' then N'Buffer IO'
          when wait_type like N'RESOURCE_SEMAPHORE_%' then N'Compilation'
          when wait_type like N'CLR_%' or wait_type like N'SQLCLR%' then N'SQL CLR'
          when wait_type like N'DBMIRROR%' or wait_type = N'MIRROR_SEND_MESSAGE' then N'Mirroring'
          when wait_type like N'XACT%' or wait_type like N'DTC_%' or wait_type like N'TRAN_MARKLATCH_%' or wait_type like N'MSQL_XACT_%' or wait_type = N'TRANSACTION_MUTEX' then N'Transaction'
          when wait_type like N'PREEMPTIVE_%' then N'Preemptive'
          when wait_type like N'BROKER_%' then N'Service Broker'
          when wait_type in (N'LOGMGR', N'LOGBUFFER', N'LOGMGR_RESERVE_APPEND', N'LOGMGR_FLUSH', N'WRITELOG', N'LOGMGR_PMM_LOG', N'CHKPT') then N'Tran Log IO'
          when wait_type in (N'ASYNC_NETWORK_IO', N'NET_WAITFOR_PACKET', N'PROXY_NETWORK_IO', N'EXTERNAL_SCRIPT_NETWORK_IO') then N'Network IO'
          when wait_type in (N'CXPACKET', N'EXCHANGE', N'CXCONSUMER') then N'CPU - Parallelism'
          when wait_type in (N'RESOURCE_SEMAPHORE', N'CMEMTHREAD', N'SOS_RESERVEDMEMBLOCKLIST', N'UTIL_PAGE_ALLOC', N'SOS_VIRTUALMEMORY_LOW', N'CMEMPARTITIONED', N'EE_PMOLOCK', N'MEMORY_ALLOCATION_EXT', N'RESERVED_MEMORY_ALLOCATION_EXT', N'MEMORY_GRANT_UPDATE') then N'Memory'
          when wait_type in (N'WAITFOR', N'WAIT_FOR_RESULTS', N'BROKER_RECEIVE_WAITFOR') then N'User Wait'
          when wait_type in (N'TRACEWRITE', N'SQLTRACE_LOCK', N'SQLTRACE_FILE_BUFFER', N'SQLTRACE_FILE_WRITE_IO_COMPLETION', N'SQLTRACE_FILE_READ_IO_COMPLETION', N'SQLTRACE_PENDING_BUFFER_WRITERS', N'SQLTRACE_SHUTDOWN', N'QUERY_TRACEOUT', N'TRACE_EVTNOTIF') then N'Tracing'
          when wait_type LIKE N'FT_%' OR wait_type IN (N'FULLTEXT GATHERER', N'MSSEARCH', N'PWAIT_RESOURCE_SEMAPHORE_FT_PARALLEL_QUERY_SYNC') then N'Full Text Search'
          when wait_type in (N'ASYNC_IO_COMPLETION', N'IO_COMPLETION', N'IO_QUEUE_LIMIT', N'WRITE_COMPLETION') then N'Other Disk IO'
          WHEN wait_type LIKE N'QDS%' THEN N'Query Store'
          WHEN wait_type LIKE N'XTP%' OR wait_type LIKE N'WAIT_XTP%' THEN N'In-Memory OLTP'
          WHEN wait_type LIKE N'PARALLEL_REDO%' THEN N'Parallel Redo'
          WHEN wait_type LIKE N'COLUMNSTORE%' THEN N'Columnstore'
          else N'Other'
          end
          ) as wait_category,
          r.wait_type,
          r.wait_time
          FROM sys.dm_exec_requests AS r
          INNER JOIN sys.dm_exec_sessions AS s ON r.session_id = s.session_id
          WHERE r.wait_type IS NOT NULL
          AND s.is_user_process = 0x1 AND r.wait_type NOT IN ('RESOURCE_QUEUE', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
          'LOGMGR_QUEUE','CHECKPOINT_QUEUE','REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TASK_STOP','CLR_MANUAL_EVENT',
          'CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT','BROKER_TO_FLUSH',
          'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'MSQL_XP', 'WAIT_FOR_RESULTS', 'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'SLEEP_TASK',
          'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'BROKER_EVENTHANDLER', 'TRACEWRITE', 'FT_IFTSHC_MUTEX', 'BROKER_RECEIVE_WAITFOR',
          'ONDEMAND_TASK_QUEUE', 'DBMIRROR_EVENTS_QUEUE', 'DBMIRRORING_CMD', 'BROKER_TRANSMITTER', 'SQLTRACE_WAIT_ENTRIES', 'SLEEP_BPOOL_FLUSH', 'SQLTRACE_LOCK',
          'DIRTY_PAGE_POLL', 'HADR_FILESTREAM_IOMGR_IOCOMPLETION', 'SP_SERVER_DIAGNOSTICS_SLEEP',
          'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', 'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', 'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', 'SOSHOST_SLEEP',
          'SP_PREEMPTIVE_SERVER_DIAGNOSTICS_SLEEP')
          AND r.wait_type NOT LIKE N'SLEEP_%'
    




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


----BUFFER IO STATISTICS ############################################################################################################


          select
          session_id,
          request_id,
          master.dbo.fn_varbintohexstr(sql_handle) as sql_handle,
          master.dbo.fn_varbintohexstr(plan_handle) as plan_handle,
          case when LEN(qt.text) < 2048 then qt.text else LEFT(qt.text, 2048) + N'...' end as query_text,
          statement_start_offset,
          statement_end_offset,
          wait_type,
          wait_time,
          wait_resource,
          blocking_session_id
          from sys.dm_exec_requests r
          outer apply sys.dm_exec_sql_text(sql_handle) as qt
          where wait_type like 'PAGEIOLATCH_%' --N'Buffer IO'/N'Buffer Latch'


----IO STATISTICS ###################################################################################


          select
          m.database_id,
          db_name(m.database_id) as database_name,
          m.file_id,
          m.name as file_name,
          m.physical_name,
          m.type_desc,
          fs.num_of_reads,
          fs.num_of_bytes_read,
          fs.io_stall_read_ms,
          fs.num_of_writes,
          fs.num_of_bytes_written,
          fs.io_stall_write_ms
          from sys.dm_io_virtual_file_stats(NULL, NULL) fs
          join sys.master_files m on fs.database_id = m.database_id and fs.file_id = m.file_id
       
----Miscellaneous Information  ###################################################################################

 
          select
          (select count(*) from sys.traces) as running_traces,
          (select count(*) from sys.databases) as number_of_databases,
          (select count(*) from sys.dm_db_missing_index_group_stats) as missing_index_count,
          (select waiting_tasks_count from sys.dm_os_wait_stats where wait_type = N'SQLCLR_QUANTUM_PUNISHMENT') as clr_quantum_waits,
          (select count(*) from sys.dm_os_ring_buffers where ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' and record like N'%NonYieldSchedBegin%') as non_yield_count,
          (select cpu_count from sys.dm_os_sys_info) as number_of_cpus,
          (select scheduler_count from sys.dm_os_sys_info) as number_of_schedulers,
          (select COUNT(*) from sys.dm_xe_sessions) as number_of_xevent_sessions 


----Buffer cache hit queries ####################################################################################################################

 
          select top 20
          r.session_id,
          r.request_id,
          --master.dbo.fn_varbintohexstr(sql_handle) as sql_handle,
          --master.dbo.fn_varbintohexstr(plan_handle) as plan_handle,
          case when LEN(qt.text) < 2048 then qt.text else LEFT(qt.text, 2048) + N'...' end as query_text,
		r.statement_start_offset, 
		r.statement_end_offset, 
		r.logical_reads,
		r.reads,
		r.writes,
		r.wait_type, 
		r.wait_time, 
		r.wait_resource,
		r.blocking_session_id,
		case when r.logical_reads > 0 then (r.logical_reads - isnull(r.reads, 0)) / convert(float, r.logical_reads)
			else NULL
			end as cache_hit_ratio
	from sys.dm_exec_requests r
		join sys.dm_exec_sessions s on r.session_id = s.session_id
		outer apply sys.dm_exec_sql_text(r.sql_handle) as qt
	where s.is_user_process = 0x1 and (r.reads > 0 or r.writes > 0)
	order by (r.reads + r.writes) desc


----LATCHES ##############################################################################################################################
 
          SELECT latch_class, wait_time_ms, waiting_requests_count,
          CASE WHEN latch_class LIKE N'ACCESS_METHODS_HOBT_COUNT'
          OR latch_class LIKE N'ACCESS_METHODS_HOBT_VIRTUAL_ROOT' THEN N'HoBT Metadata'
          WHEN latch_class LIKE N'ACCESS_METHODS_DATASET_PARENT'
          OR latch_class LIKE N'ACCESS_METHODS_SCAN_RANGE_GENERATOR'
          OR latch_class LIKE N'NESTING_TRANSACTION%' THEN N'Parallelism'
          WHEN latch_class LIKE N'LOG_MANAGER' THEN N'Tran LogIO'
          WHEN latch_class LIKE N'TRACE_CONTROLLER' THEN N'Trace'
          WHEN latch_class LIKE N'DBCC_MULTIOBJECT_SCANNER' THEN N'Parallelism - DBCC CHECK_'
          WHEN latch_class LIKE N'FGCB_ADD_REMOVE' THEN N'Other IO'
          WHEN latch_class LIKE N'DATABASE_MIRRORING_CONNECTION' THEN N'Mirroring - Busy'
          WHEN latch_class LIKE N'BUFFER' THEN N'Buffer Pool'
          ELSE N'Other' END AS 'latch_category'

          FROM sys.dm_os_latch_stats
          WHERE wait_time_ms > 0
       
---PAGE IO Latch and Missing index identified ####################################################################################################################
 
          select db_name(d.database_id) as database_name,
          quotename(object_schema_name(d.object_id, d.database_id)) + N'.' + quotename(object_name(d.object_id, d.database_id)) as object_name,
          d.database_id,
          d.object_id,
          d.page_io_latch_wait_count,
          d.page_io_latch_wait_in_ms,
          d.range_scans,
          d.index_lookups,
          case when mid.database_id is null then 'N' else 'Y' end as missing_index_identified
          from (select
          database_id,
          object_id,
          row_number() over (partition by database_id order by sum(page_io_latch_wait_in_ms) desc) as row_number,
          sum(page_io_latch_wait_count) as page_io_latch_wait_count,
          sum(page_io_latch_wait_in_ms) as page_io_latch_wait_in_ms,
          sum(range_scan_count) as range_scans,
          sum(singleton_lookup_count) as index_lookups
          from sys.dm_db_index_operational_stats(NULL, NULL, NULL, NULL)
          where page_io_latch_wait_count > 0
          group by database_id, object_id ) as d
          left join (select distinct database_id, object_id from sys.dm_db_missing_index_details) as mid
          on mid.database_id = d.database_id and mid.object_id = d.object_id
          where d.row_number >= 20
		--  and db_name(d.database_id)='DB_NAME'
------Missing Index Script #############################################################################################################################################




          select 		  db_name(d.database_id) dbName,
REPLACE(REPLACE(CONCAT('CREATE INDEX [IX_' , replace(replace(replace(d.statement ,'[',''),']',''),'.','_'),' ON '+d.statement,' (' , d.equality_columns,',',d.inequality_columns, ') INCLUDE (',d.included_columns,')'),'INCLUDE ()',''),',)',')') Index_DDL,
		  
 d.object_id, d.index_handle, d.equality_columns, d.inequality_columns, d.included_columns, d.statement as fully_qualified_object,
          gs.avg_total_user_cost,gs.avg_user_impact, 
		  FLOOR((CONVERT(NUMERIC(19,3), gs.user_seeks) + CONVERT(NUMERIC(19,3), gs.user_scans)) * CONVERT(NUMERIC(19,3), gs.avg_total_user_cost) * CONVERT(NUMERIC(19,3), gs.avg_user_impact)) AS Score
          from sys.dm_db_missing_index_groups g
          join sys.dm_db_missing_index_group_stats gs on gs.group_handle = g.index_group_handle
          join sys.dm_db_missing_index_details d on g.index_handle = d.index_handle
          --where db_name(d.database_id)='DB_NAME'
		  order by gs.avg_user_impact desc





-----XTENDED EVENTS #################################################################################################


          select convert(bigint, address) xeaddress,
          case when row_num = 1 then session_name else NULL end as session_name,
          case when row_num = 1 then create_time else NULL end as create_time,
          case when row_num = 1 then target_name else NULL end as target_name,
          case when row_num = 1 then execution_count else NULL end as execution_count,
          case when row_num = 1 then execution_duration_ms else NULL end as execution_duration_ms,
          case when row_num = 1 then dropped_event_count else NULL end as dropped_event_count,
          case when row_num = 1 then buffer_policy_desc else NULL end as buffer_policy_desc,
          case when row_num = 1 then total_buffer_size else NULL end as total_buffer_size,
          event_name,
          action_name


          from (
          select s.address, ROW_NUMBER() over (partition by s.address order by sea.event_name, sea.action_name ) as row_num,
          s.name session_name ,s.create_time, st.target_name, st.execution_count, st.execution_duration_ms,
          sea.action_name, sea.event_name, s.dropped_event_count, s.total_buffer_size, s.buffer_policy_desc
          from sys.dm_xe_sessions s
          inner join sys.dm_xe_session_targets st
          on s.address = st.event_session_address
          inner join sys.dm_xe_session_event_actions sea
          on s.address = sea.event_session_address ) as inner_t
 
-----CPU Utilization #########################################################################################################################


          declare @ms_now bigint

          select @ms_now = ms_ticks from sys.dm_os_sys_info;

          select top 15 record_id,
          dateadd(ms, -1 * (@ms_now - [timestamp]), GetDate()) as EventTime,
          SQLProcessUtilization,
          SystemIdle,
          100 - SystemIdle - SQLProcessUtilization as OtherProcessUtilization
          from (
          select
          record.value('(./Record/@id)[1]', 'int') as record_id,
          record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') as SystemIdle,
          record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') as SQLProcessUtilization,
          timestamp
          from (
          select timestamp, convert(xml, record) as record
          from sys.dm_os_ring_buffers
          where ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
          and record like '%SystemHealth%') as x
		) as y 
