USE [SAPDB]
GO

/****** Object:  StoredProcedure [dbo].[usp_monitor_long_running_jobs]    Script Date: 9/7/2025 10:55:50 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






CREATE OR ALTER procedure [dbo].[usp_index_maintenance_jobs]
as


/*
*Author: Collins Robert
*Date:9/07/2025
*Date modified: 
*Description:################################################################################
			 #This procedure maintains indexes on SAPDB Database#
             ################################################################################
*/
declare

 
@Index varchar(Max);
 

 

declare sql_index_Cur CURSOR FOR

SELECT

concat('alter index [',idx.name ,'] on [',
OBJECT_NAME(idx.object_id),'] REBUILD') IndexRebuild
  --OBJECT_NAME(idx.object_id) AS TableName,
  --idx.name AS IndexName,
  --ips.index_type_desc AS IndexType,
  --ips.avg_fragmentation_in_percent AS FragmentationPercentage,
  --ips.page_count AS PageCount
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') ips
JOIN sys.indexes idx
  ON idx.object_id = ips.object_id
  AND idx.index_id = ips.index_id
WHERE ips.database_id = DB_ID()
  AND idx.name IS NOT NULL
  and    ips.avg_fragmentation_in_percent>10


OPEN sql_index_Cur
fetch next from sql_index_Cur 
INTO    @Index 

while @@FETCH_STATUS = 0
 Begin
 
 select @Index
		
	
	fetch next from sql_index_Cur 
INTO   @Index
END

Close sql_index_Cur;
Deallocate sql_index_Cur;






GO


