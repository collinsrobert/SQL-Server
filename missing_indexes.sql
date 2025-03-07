
SELECT user_seeks
* avg_total_user_cost
* (avg_user_impact * 0.01) AS [Index_Useful]
,igs.last_user_seek
,id.statement AS [Statement]
,id.equality_columns
,id.inequality_columns
,id.included_columns
,igs.unique_compiles
,igs.user_seeks
,igs.avg_total_user_cost
,igs.avg_user_impact
FROM sys.dm_db_missing_index_group_stats AS igs
INNER JOIN sys.dm_db_missing_index_groups AS ig
ON igs.group_handle = ig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS id
ON ig.index_handle = id.index_handle
ORDER BY [Index_Useful] DESC;
