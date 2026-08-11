SELECT TOP (20)
    qs.total_logical_reads,
    qs.total_logical_reads / NULLIF(qs.execution_count, 0) AS avg_logical_reads,
    qs.execution_count,
    qs.total_elapsed_time / 1000000.0 AS total_elapsed_seconds,
    qs.total_elapsed_time / NULLIF(qs.execution_count, 0) / 1000000.0 AS avg_elapsed_seconds,
    qs.total_worker_time / 1000000.0 AS total_cpu_seconds,
    SUBSTRING(
        st.text,
        (qs.statement_start_offset / 2) + 1,
        (
            (
                CASE qs.statement_end_offset
                    WHEN -1 THEN DATALENGTH(st.text)
                    ELSE qs.statement_end_offset
                END
                - qs.statement_start_offset
            ) / 2
        ) + 1
    ) AS statement_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.dbid = DB_ID()
ORDER BY qs.total_logical_reads desc, total_elapsed_seconds DESC;
