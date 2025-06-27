SELECT
OBJECT_SCHEMA_NAME(i.OBJECT_ID) AS [SchemaName],
OBJECT_NAME(i.OBJECT_ID) AS [ObjectName],
i.name AS [IndexName],
i.type_desc AS [IndexType],
ius.user_updates AS [UserUpdates],
ius.last_user_update AS [LastUserUpdate]
FROM sys.indexes i
INNER JOIN sys.dm_db_index_usage_stats ius
ON ius.OBJECT_ID = i.OBJECT_ID AND ius.index_id = i.index_id
WHERE OBJECTPROPERTY(i.OBJECT_ID, 'IsUserTable') = 1 -- User Indexes
AND NOT(user_seeks > 0 OR user_scans > 0 or user_lookups > 0)
AND i.is_primary_key = 0
AND i.is_unique = 0
ORDER BY ius.user_updates DESC, SchemaName, ObjectName, IndexName
