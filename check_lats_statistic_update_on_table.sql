SELECT
    OBJECT_NAME(s.object_id) AS table_name,
    s.name AS stats_name,
    sp.last_updated
FROM sys.stats s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp

where OBJECT_NAME(s.object_id) ='drives'
ORDER BY sp.last_updated desc
