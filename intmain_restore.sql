/****** Object:  StoredProcedure [EDWNEW].[INDMAINT_RESTORE]    Script Date: 6/24/2025 3:46:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [SCHEMANAME].[INDMAINT_RESTORE]
    @tname NVARCHAR(128),   -- Table name in uppercase
    @sfunct CHAR(1)         -- 'R' = Rebuild, 'C' = Create from DDL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ind_name NVARCHAR(128);
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @v_tbl INT;

    -- === Rebuild Unusable (Disabled) Indexes ===
    IF @sfunct = 'R'
    BEGIN
        DECLARE ind_cursor CURSOR FOR
            SELECT i.name AS ind_name
            FROM sys.indexes i
            JOIN sys.tables t ON i.object_id = t.object_id
            WHERE UPPER(t.name) = UPPER(@tname)
              AND i.type_desc = 'NONCLUSTERED'  -- Simulating bitmap index logic
              AND i.is_unique = 0
              AND i.is_disabled = 1;

        OPEN ind_cursor;
        FETCH NEXT FROM ind_cursor INTO @ind_name;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @sql = 'ALTER INDEX [' + @ind_name + '] ON [SCHEMANAME].[' + @tname + '] REBUILD WITH (ONLINE = ON, MAXDOP = 4)';
            PRINT 'Executing: ' + @sql;
            EXEC(@sql);
            FETCH NEXT FROM ind_cursor INTO @ind_name;
        END

        CLOSE ind_cursor;
        DEALLOCATE ind_cursor;

        PRINT 'Index rebuild complete.';
    END

    -- === Recreate Dropped Indexes from IDX_DDL ===
    ELSE IF @sfunct = 'C'
    BEGIN
        -- Check if IDX_DDL table exists
        SELECT @v_tbl = COUNT(*) 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_NAME = 'IDX_DDL';

        IF @v_tbl = 0
        BEGIN
            PRINT 'THE DDL TABLE DOES NOT EXIST';
            RETURN;
        END

        DECLARE @idx_name NVARCHAR(128);
        DECLARE @idx_ddl NVARCHAR(MAX);

        DECLARE ddl_cursor CURSOR FOR
            SELECT idx_name, idx_ddl
            FROM IDX_DDL
            WHERE UPPER(table_name) = UPPER(@tname);

        OPEN ddl_cursor;
        FETCH NEXT FROM ddl_cursor INTO @idx_name, @idx_ddl;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT 'Recreating index: ' + @idx_name;
            EXEC(@idx_ddl);

           -- SET @sql = 'DELETE FROM IDX_DDL WHERE table_name = ''' + @tname + ''' AND idx_name = ''' + @idx_name + '''';
            PRINT 'Cleaning up DDL record: ' + @sql;
            EXEC(@sql);

            FETCH NEXT FROM ddl_cursor INTO @idx_name, @idx_ddl;
        END

        CLOSE ddl_cursor;
        DEALLOCATE ddl_cursor;

        COMMIT TRANSACTION;
        PRINT 'Index recreation complete.';
    END

    -- === Invalid or Null Operation ===
    ELSE
    BEGIN
        PRINT 'Invalid operation. Use ''R'' to rebuild indexes or ''C'' to recreate dropped indexes.';
    END
END
GO


