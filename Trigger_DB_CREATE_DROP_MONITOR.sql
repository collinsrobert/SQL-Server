USE [master]
GO

/****** Object:  DdlTrigger [DB_CREATE_DROP_MONITOR]    Script Date: 9/29/2024 4:15:56 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



create TRIGGER [DB_CREATE_DROP_MONITOR]
ON ALL SERVER with execute as '<a user that has access to execute sp_send_dbmail on msdb>'
FOR CREATE_DATABASE, DROP_DATABASE
AS

/*****************

Author: Collins Robert
Description: This Creates a Server Trigger that sends out an email to the DBA DL when
			 a database is created or dropped
Date:  2024/09/29


*****************/
DECLARE @v_body varchar (max)
Declare @v_subject varchar (100)
Declare @v_tsql varchar (max)
-------Retrive the email profiler setup on SQL Server agent
  
 declare @dirtable table ([value] varchar(max),
[Data] varchar(max) ) ;
declare @profile varchar(max)
insert into @dirtable
exec xp_instance_regread  N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'DatabaseMailProfile'
select @profile=[Data] from @dirtable



  
Set @v_tsql = EVENTDATA(). value
        ('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]','varchar(max)' )
SET @v_body =  '<html><body><b>Username: </b>' + UPPER (SUSER_NAME()) + '<p><b>

                  Server Name: </b>' + @@SERVERNAME + '<p><b>

                  Time: </b>'      + CONVERT(varchar (25), Getdate()) + '<p><b>

                  Client Hostname: </b>' + HOST_NAME() + '<p><b>

                  T-SQL: </b>' +  @v_tsql + '</body></html>'
                 

BEGIN
 -- PRINT 'Make sure you have informed all DBAs before creating databases. This event has been logged'
 
  if ( eventdata().value ('(/EVENT_INSTANCE/EventType)[1]', 'sysname') = 'CREATE_DATABASE')
      set @v_subject = 'A new database has been created!'
  else
      set @v_subject = 'A database has been removed!'
     --dataservices@ingrambarge.com
  EXEC msdb .dbo. sp_send_dbmail @profile_name = @profile,
                                                     @recipients = 'email@example.com' ,
                                                     @subject = @v_subject,
                                                     @body_format = 'HTML',
                                                     @importance = 'High',
                                                     @body = @v_body
END




GO

ENABLE TRIGGER [DB_CREATE_DROP_MONITOR] ON ALL SERVER
GO


