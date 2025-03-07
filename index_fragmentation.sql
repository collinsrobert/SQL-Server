--- USE Database_Name
--GO
SELECT SCHEMA_NAME(so.schema_id) AS [SchemaName],
OBJECT_NAME(idx.OBJECT_ID) AS [TableName],
idx.name AS [IndexName],
idxstats.index_type_desc AS [Index_Type_Desc],
CAST(idxstats.avg_fragmentation_in_percent
AS decimal(5,2)) AS [Frag_Pct],
idxstats.fragment_count,
idxstats.page_count,
idx.fill_factor
FROM sys.dm_db_index_physical_stats
(DB_ID(), NULL, NULL, NULL, ‘DETAILED’) idxstats
INNER JOIN sys.indexes idx
ON idx.OBJECT_ID = idxstats.OBJECT_ID
AND idx.index_id = idxstats.index_id
INNER JOIN sys.objects so
ON so.object_id = idx.object_id
WHERE idxstats.avg_fragmentation_in_percent > 20
ORDER BY idxstats.avg_fragmentation_in_percent DESC
