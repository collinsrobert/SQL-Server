USE [master]
GO

/****** Object:  StoredProcedure [dbo].[usp_SQLServerRestartNotification]    Script Date: 9/10/2021 7:11:23 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



create PROCEDURE [dbo].[usp_SQLServerRestartNotification]
AS
BEGIN
-- Detect if SQL Server was restarted.
DECLARE @UpTimeDays int
DECLARE @SQLServerStarted varchar(20)
DECLARE @rc int
DECLARE @msg varchar(1000)

SET @UpTimeDays = (select DateDiff(D, CrDate, GetDate()) from master..SysDatabases where name = 'TempDb')
IF @UpTimeDays = 0
BEGIN
    SET @SQLServerStarted = (select convert(varchar(20), CrDate, 113) from master..SysDatabases where name = 'TempDb')
    SET @msg = 'The SQL Server <b>' + @@SERVERNAME + '</b> was restarted on <b>' + @SQLServerStarted + '</b>'
    EXEC @rc = msdb.dbo.sp_send_dbmail
	@profile_name = 'Database Mail Profile',
        @recipients = 'alert@luisight.com',
        @importance = 'high',
        @subject = 'SQL Server Restart Notification',
        @body_format = 'html',
        @body = @msg,
        @exclude_query_output = 1
    IF @rc = 1 RAISERROR('sp_send_dbmail Failed', 16, 1)
END
END

GO

EXEC sp_procoption N'[dbo].[usp_SQLServerRestartNotification]', 'startup', '1'
GO
