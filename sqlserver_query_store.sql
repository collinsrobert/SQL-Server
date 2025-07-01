ALTER DATABASE F92DEV
SET QUERY_STORE = ON;

ALTER DATABASE F92DEV
SET QUERY_STORE (
    OPERATION_MODE = READ_WRITE, -- Start collecting
    CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), -- Keep 30 days of data
    DATA_FLUSH_INTERVAL_SECONDS = 900, -- Flush to disk every 15 minutes
    INTERVAL_LENGTH_MINUTES = 15, -- Data aggregation period
    MAX_STORAGE_SIZE_MB = 10240, -- Cap storage usage (tune as needed)
    QUERY_CAPTURE_MODE = AUTO, -- Smart capture; skips trivial queries
    SIZE_BASED_CLEANUP_MODE = AUTO, -- Automatically clean when near limit
    MAX_PLANS_PER_QUERY = 200 -- Helps track regressions but not overload
);


--Monitor Space Usage

SELECT actual_state_desc, current_storage_size_mb, max_storage_size_mb
FROM sys.database_query_store_options;



---Detect plan regression


-- Queries with multiple plans (possible regressions)
--This finds queries where newer plans perform worse than older ones:
SELECT 
    qt.query_sql_text,
    q.query_id,
    COUNT(DISTINCT qs.plan_id) AS plan_count,
    MAX(rs.avg_duration / 1000.0) AS max_duration_ms,
    MIN(rs.avg_duration / 1000.0) AS min_duration_ms,
    MAX(rs.avg_duration / 1000.0) - MIN(rs.avg_duration / 1000.0) AS duration_diff_ms
FROM 
    sys.query_store_query_text qt
JOIN 
    sys.query_store_query q ON qt.query_text_id = q.query_text_id
JOIN 
    sys.query_store_plan qs ON q.query_id = qs.query_id
JOIN 
    sys.query_store_runtime_stats rs ON qs.plan_id = rs.plan_id
GROUP BY 
    qt.query_sql_text, q.query_id
HAVING 
    COUNT(DISTINCT qs.plan_id) > 1
    AND MAX(rs.avg_duration) > MIN(rs.avg_duration) * 2  -- large difference
ORDER BY 
    duration_diff_ms DESC;




---top Top 10 Most Expensive Queries by Average Duration



SELECT TOP 10 
    qt.query_sql_text,
    q.query_id,
    p.plan_id,
    rs.avg_duration / 1000.0 AS avg_duration_ms,
    rs.avg_cpu_time / 1000.0 AS avg_cpu_ms,
    rs.count_executions,
    rs.last_execution_time,
	rsi.runtime_stats_interval_id
	--,p.query_plan
FROM 
    sys.query_store_query_text AS qt
JOIN 
    sys.query_store_query AS q ON qt.query_text_id = q.query_text_id
JOIN 
    sys.query_store_plan AS p ON q.query_id = p.query_id
JOIN 
    sys.query_store_runtime_stats AS rs ON p.plan_id = rs.plan_id
	
	JOIN sys.query_store_runtime_stats_interval AS rsi ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id

WHERE 
    rs.last_execution_time >= DATEADD(DAY, -7, GETDATE())
ORDER BY 
    rs.avg_duration DESC;

