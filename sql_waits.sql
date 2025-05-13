
          select
          wait_type,
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
          waiting_tasks_count as num_waits,
          wait_time_ms as wait_time,
          max_wait_time_ms
          from sys.dm_os_wait_stats
          where waiting_tasks_count > 0 AND wait_type NOT IN ('RESOURCE_QUEUE', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
          'LOGMGR_QUEUE','CHECKPOINT_QUEUE','REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TASK_STOP','CLR_MANUAL_EVENT',
          'CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT','BROKER_TO_FLUSH',
         'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'MSQL_XP', 'WAIT_FOR_RESULTS', 'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'SLEEP_TASK',
          'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'BROKER_EVENTHANDLER', 'TRACEWRITE', 'FT_IFTSHC_MUTEX', 'BROKER_RECEIVE_WAITFOR',
         'ONDEMAND_TASK_QUEUE', 'DBMIRROR_EVENTS_QUEUE', 'DBMIRRORING_CMD', 'BROKER_TRANSMITTER', 'SQLTRACE_WAIT_ENTRIES', 'SLEEP_BPOOL_FLUSH', 'SQLTRACE_LOCK',
          'DIRTY_PAGE_POLL', 'HADR_FILESTREAM_IOMGR_IOCOMPLETION', 'SP_SERVER_DIAGNOSTICS_SLEEP',
          'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', 'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', 'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', 'SOSHOST_SLEEP',
          'SP_PREEMPTIVE_SERVER_DIAGNOSTICS_SLEEP')
          AND wait_type NOT LIKE N'SLEEP_%'

