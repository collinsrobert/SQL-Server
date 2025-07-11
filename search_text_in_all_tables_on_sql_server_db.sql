DECLARE @SearchValue NVARCHAR(100) = 'Bartlett'; -- <-- Replace this
DECLARE @TableName NVARCHAR(256);
DECLARE @ColumnName NVARCHAR(128);
DECLARE @DataType NVARCHAR(128);
DECLARE @SQL NVARCHAR(MAX) = '';

-- Cursor to loop through all columns of all tables
DECLARE cur CURSOR FOR
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType
FROM 
    sys.columns c
    JOIN sys.tables t ON c.object_id = t.object_id
    JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE 
    ty.name IN ('char', 'nchar', 'varchar', 'nvarchar', 'text', 'ntext');

OPEN cur;
FETCH NEXT FROM cur INTO @TableName, @ColumnName, @DataType;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL += '
    IF EXISTS (
        SELECT 1 FROM [' + @TableName + '] 
        WHERE [' + @ColumnName + '] LIKE ''%' + @SearchValue + '%''
    )
    PRINT ''Found in ' + @TableName + '.' + @ColumnName + ''';';

    FETCH NEXT FROM cur INTO @TableName, @ColumnName, @DataType;
END

CLOSE cur;
DEALLOCATE cur;

-- Execute the dynamic SQL
EXEC sp_executesql @SQL;
