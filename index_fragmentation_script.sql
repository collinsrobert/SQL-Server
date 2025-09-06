SELECT

concat('alter index ',idx.name ,' on ',
OBJECT_NAME(idx.object_id),' REBUILD'),
  OBJECT_NAME(idx.object_id) AS TableName,
  idx.name AS IndexName,
  ips.index_type_desc AS IndexType,
  ips.avg_fragmentation_in_percent AS FragmentationPercentage,
  ips.page_count AS PageCount
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') ips
JOIN sys.indexes idx
  ON idx.object_id = ips.object_id
  AND idx.index_id = ips.index_id
WHERE ips.database_id = DB_ID()
  AND idx.name IS NOT NULL
  and  OBJECT_NAME(idx.object_id) in ('TABLE_NAME1','TABLE_NAME2'
)
ORDER BY FragmentationPercentage DESC;
