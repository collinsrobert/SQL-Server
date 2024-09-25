use IMG_Dataservices
go


create proc sp_fix_all_db_orphaned_users_DR

as
/*
*Author: Collins Were
*Date:9/2/2022
*Date modified:     BY: 
*Description:###################################################################################
			 #This procedure is used to fix orphaned user on all databases where such exists.###
             ###################################################################################
*/

exec sp_MSforeachdb ' use [?] DECLARE @AutoFixCommand NVARCHAR(MAX)
  
   declare orphans_cur CURSOR for
   
   SELECT 
        ''EXEC sp_change_users_login ''''Auto_Fix'''', '''''' + dp.[name] + '''''';''
   FROM sys.database_principals dp
   INNER JOIN sys.server_principals sp
       ON dp.[name] = sp.[name] COLLATE DATABASE_DEFAULT
   WHERE dp.[type_desc] IN (''SQL_USER'', ''WINDOWS_USER'', ''WINDOWS_GROUP'')
   AND sp.[type_desc] IN (''SQL_LOGIN'', ''WINDOWS_LOGIN'', ''WINDOWS_GROUP'')
   AND dp.[sid] <> sp.[sid]

   open orphans_cur
   fetch next from orphans_cur into @AutoFixCommand
   WHILE @@FETCH_STATUS=0
   Begin
       
       --PRINT @AutoFixCommand
	   execute (@AutoFixCommand)
	   
  fetch next from orphans_cur into @AutoFixCommand
   END
   close orphans_cur
   deallocate orphans_cur'
