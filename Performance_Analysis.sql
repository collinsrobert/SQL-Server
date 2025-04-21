---Memory Analysis

SELECT 
    total_physical_memory_kb / 1024 AS Total_Memory_MB,
    available_physical_memory_kb / 1024 AS Available_Memory_MB,
    system_memory_state_desc
FROM 
    sys.dm_os_sys_memory;


	SELECT 
    physical_memory_in_use_kb / 1024 AS SQLServer_Memory_MB,
    page_fault_count,
    memory_utilization_percentage
FROM 
    sys.dm_os_process_memory;


----Blocking Locks
	SELECT 
    session_id,
    blocking_session_id,
    wait_type,
    wait_time,
    status,
    cpu_time--,
    --memory_usage,
    --last_request_start_time,
    --last_request_end_time
FROM 
    sys.dm_exec_requests
WHERE 
    status = 'running'

	and blocking_session_id>0
--ORDER BY 
    --memory_usage DESC;
