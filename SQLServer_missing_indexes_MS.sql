		exec sp_executesql @sql_missingIndexes=N'
          select d.database_id, d.object_id, d.index_handle, d.equality_columns, d.inequality_columns, d.included_columns, d.statement as fully_qualified_object,
          gs.*, FLOOR((CONVERT(NUMERIC(19,3), gs.user_seeks) + CONVERT(NUMERIC(19,3), gs.user_scans)) * CONVERT(NUMERIC(19,3), gs.avg_total_user_cost) * CONVERT(NUMERIC(19,3), gs.avg_user_impact)) AS Score
		  ,CONCAT(''CREATE INDEX [IX_'',OBJECT_NAME(d.object_id,d.database_id),''_'', REPLACE(REPLACE(REPLACE(ISNULL(d.equality_columns,''''),'', '',''_''),''['',''''),'']'','''' ),
''_'',REPLACE(REPLACE(REPLACE(ISNULL(d.inequality_columns,''''),'', '',''_''),''['',''''),'']'',''''),'']'','' ON '' ,d.statement,
		  '' ('',ISNULL (d.equality_columns,'''') ,CASE WHEN d.equality_columns IS NOT NULL AND d.inequality_columns 
IS NOT NULL THEN '','' ELSE '''' end, ISNULL (d.inequality_columns, ''''),'')'',ISNULL ('' INCLUDE ('' + d.included_columns + '')'', '''')) IndexCreatScript
          from sys.dm_db_missing_index_groups g
          join sys.dm_db_missing_index_group_stats gs on gs.group_handle = g.index_group_handle
          join sys.dm_db_missing_index_details d on g.index_handle = d.index_handle
          where d.database_id = isnull(@DatabaseID , d.database_id) and d.object_id = isnull(@ObjectID, d.object_id)
        ',@params=N'@DatabaseID NVarChar(max), @ObjectID NVarChar(max)',@DatabaseID=NULL,@ObjectID=NULL
