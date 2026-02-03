SELECT qp.query_plan_hash, qs.query_hash,
qrsi.end_time as interval_end_time,
qs.query_id,
qp.plan_id,
qt.query_sql_text,
TRY_CAST(qp.query_plan as XML) as query_plan,
qrs.count_executions
FROM sys.query_store_query as qs
JOIN sys.query_store_query_text as qt on qs.query_text_id=qt.query_text_id
JOIN sys.query_store_plan as qp on qs.query_id=qp.query_id
JOIN sys.query_store_runtime_stats qrs on qp.plan_id = qrs.plan_id
JOIN sys.query_store_runtime_stats_interval qrsi on qrs.runtime_stats_interval_id=qrsi.runtime_stats_interval_id
WHERE --query_plan_hash =  @query_plan_hash and query_hash = @query_hash
query_sql_text like '%query%'
ORDER BY interval_end_time, query_id;
