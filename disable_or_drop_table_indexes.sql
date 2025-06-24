/****** Object:  StoredProcedure [EDWNEW].[sp_ind_Maint_Remove]    Script Date: 6/24/2025 11:31:24 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE proc [schema].[sp_ind_Maint_Remove]
@TableName varchar(100) ,
@schemaName varchar(100) ,
@task char
as
/*
#########################################################################################################
AUTHOR: Collins Robert
Date: 2025/06/23
Purpose:This proc is used to disable indexes or drop them from a table before it is loaded with data.

@TableName supply the table name
@schemaName supply the schema name
@task char supply the values below
    U - Mark the indexes on the table unusable.
    D - Drop the indexes from the table.
Example; 
		When dropping indexes you execute below
			exec schema.sp_ind_Maint_Remove 'TABLENAME','SCHEMANAME','D'

		When disabling indexes you execute below
			exec schema.sp_ind_Maint_Remove 'TABLENAME','SCHEMANAME','U'
                                  
##########################################################################################################
*/
Begin

DECLARE @sql NVARCHAR(MAX) = '';

if @task='U'
		Begin
					DECLARE idx_cursor CURSOR FOR
					SELECT CONCAT('ALTER INDEX [' , i.name, '] ON ' ,s.name, '.' ,o.name, ' DISABLE;' )--+ CHAR(13) + CHAR(10)
					FROM sys.indexes i
					INNER JOIN sys.objects o ON i.object_id = o.object_id
					INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
					WHERE i.type_desc = 'NONCLUSTERED'
					AND o.name = @TableName
					AND s.name = @schemaName;
					----print @sql
					--exec (@sql)

					OPEN idx_cursor

					FETCH NEXT FROM idx_cursor
					INTO @sql

					WHILE @@FETCH_STATUS = 0
					BEGIN
					print @sql
					exec (@sql)

					FETCH NEXT FROM idx_cursor INTO @sql
					END

				CLOSE idx_cursor
				DEALLOCATE idx_cursor

				print 'Indexes have been disabled'

		end --- end process of disabling indexes

if @task='D'
		Begin
					DECLARE idx_cursor CURSOR FOR
					SELECT CONCAT('DROP INDEX [' ,i.name, '] ON ' ,s.name, '.' ,o.name, ' ;') --+ CHAR(13) + CHAR(10)
					FROM sys.indexes i
					INNER JOIN sys.objects o ON i.object_id = o.object_id
					INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
					WHERE i.type_desc = 'NONCLUSTERED'
					AND o.name = @TableName
					AND s.name = @schemaName;
					--print @sql
					--exec (@sql)
					OPEN idx_cursor

					FETCH NEXT FROM idx_cursor
					INTO @sql

					WHILE @@FETCH_STATUS = 0
					BEGIN
					print @sql
					exec (@sql)

					FETCH NEXT FROM idx_cursor INTO @sql
					END

				CLOSE idx_cursor
				DEALLOCATE idx_cursor

				print 'Indexes have been dropped'

		end --- end process of dropping indexes

---end of proc
end
GO


