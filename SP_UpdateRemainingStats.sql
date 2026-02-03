/****** Object:  StoredProcedure [dbo].[SP_UpdateRemainingStats]    Script Date: 2/3/2026 10:14:09 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROC [dbo].[SP_UpdateRemainingStats]
as
begin


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~->

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~->

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~->

*/

DECLARE @SQL VARCHAR(500)
DECLARE STATS_cursor CURSOR FOR
SELECT DISTINCT --SCHEMA_NAME(SCHEMA_ID()),
   CONCAT( 'UPDATE STATISTICS ',SCHEMA_NAME(T.SCHEMA_ID),'.',OBJECT_NAME(S.object_id)) 
   ---AS [ObjectName]--,
    --[name] AS [StatisticName],
    --STATS_DATE(S.[object_id], 
    --[stats_id]) AS [StatisticUpdateDate]
FROM 


    sys.stats S JOIN SYS.objects T on T.OBJECT_ID=S.OBJECT_ID
	
	WHERE STATS_DATE(S.[object_id], 
    [stats_id]) <=GETDATE()-1
	
	AND OBJECT_NAME(S.object_id) NOT LIKE 'SYS%'
	AND SCHEMA_NAME(T.SCHEMA_ID) NOT IN ('SYS','DBO') 
OPEN STATS_cursor
FETCH NEXT FROM STATS_cursor INTO @SQL
WHILE @@FETCH_STATUS = 0
BEGIN
--PRINT @SQL

exec(@SQL)

FETCH NEXT FROM STATS_cursor INTO @SQL
END
CLOSE STATS_cursor
DEALLOCATE STATS_cursor

end


GO


