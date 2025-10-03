USE [master]
GO

/****** Object:  DdlTrigger [DB_CREATE_DROP_MONITOR]    Script Date: 6/12/2018 3:42:28 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create TRIGGER [DB_CREATE_DROP_MONITOR]
ON ALL SERVER with execute as 'dbamon'
FOR CREATE_DATABASE, DROP_DATABASE
AS
DECLARE @v_body varchar (max)
Declare @v_subject varchar (100)
Declare @v_tsql varchar (max)
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
   
  EXEC msdb .dbo. sp_send_dbmail @profile_name = 'Default SQL Server Database Mail Profile',
                                                     @recipients = 'alert@liusight.com' ,
                                                     @subject = @v_subject,
                                                     @body_format = 'HTML',
                                                     @importance = 'High',
                                                     @body = @v_body
END




GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

ENABLE TRIGGER [DB_CREATE_DROP_MONITOR] ON ALL SERVER
GO


