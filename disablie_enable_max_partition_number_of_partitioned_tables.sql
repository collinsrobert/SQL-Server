DECLARE @TableName NVARCHAR(128) = 'TABLE_NAME';
DECLARE @SchemaName NVARCHAR(128) = 'SCHEMANAME';
 
DECLARE @IndexName NVARCHAR(128);
DECLARE @ObjectID INT;
DECLARE @MaxPartition INT;
DECLARE @SQL NVARCHAR(MAX);
 
-- Step 1: Get the object ID of the table
SELECT @ObjectID = OBJECT_ID(@SchemaName + '.' + @TableName);
 
-- Step 2: Find the highest partition number on the table
SELECT @MaxPartition = MAX(p.partition_number)
FROM sys.partitions p
WHERE p.object_id = @ObjectID;
 
-- Step 3: Cursor to disable all indexes with the max partition number
DECLARE idx_cursor CURSOR FOR
SELECT DISTINCT i.name
FROM sys.indexes i
JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
WHERE i.object_id = @ObjectID
  AND i.type_desc = 'NONCLUSTERED'
  AND p.partition_number = @MaxPartition;
 
OPEN idx_cursor;
FETCH NEXT FROM idx_cursor INTO @IndexName;
 
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @SchemaName + '].[' + @TableName + '] DISABLE;';
    PRINT 'Disabling: ' + @SQL;
    EXEC(@SQL);
 
    FETCH NEXT FROM idx_cursor INTO @IndexName;
END
 
CLOSE idx_cursor;
DEALLOCATE idx_cursor;
 
PRINT '✅ All indexes on max partition disabled.';
