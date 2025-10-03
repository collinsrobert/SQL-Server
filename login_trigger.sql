--User Login Trigger

--Create user_login_record Table

--* If the Liusight database already exists and the user_login_record table does not exist then create the table. *

USE [Liusight]
GO

/****** Object:  Table [dbo].[user_login_record]    Script Date: 7/31/2014 4:38:54 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[user_login_record](
	[Login_date] [datetime2](7) NULL,
	[SPID] [int] NULL,
	[Server_Name] [nvarchar](100) NULL,
	[Login_Name] [nvarchar](100) NULL,
	[Login_Type] [nvarchar](100) NULL,
	[Login_SID] [nvarchar](100) NULL,
	[Client_IP] [nvarchar](100) NULL,
	[Client_Hostname] [nvarchar](50) NULL,
	[Is_Pooled] [tinyint] NULL
) ON [PRIMARY]

GO

--Create User Login Trigger

--•	Be sure the dbamon login not only has been created but is db_owner on Liusight.
--•	Run this script to create the User_Login_Audit trigger only after the above have been completed. If not then the ability to logon to the instance using SSMS will be blocked.  If that happens go to the last page for the steps to disable the trigger via DAC.

USE [master]
GO

/****** Object:  DdlTrigger [User_Login_audit]    Script Date: 7/31/2014 1:46:53 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE trigger [User_Login_audit] on all server with execute as 'dbamon'
after logon
as
 DECLARE @eventdata xml;
 DECLARE @hostname NVARCHAR(50);
 SET @eventdata = EVENTDATA();
 SET @hostname = HOST_NAME();
  
 if @eventdata.value('(/EVENT_INSTANCE/LoginName)[1]','nvarchar(100)') not in ('NT AUTHORITY\SYSTEM') 
--	AND @eventdata.value('(/EVENT_INSTANCE/ClientHost)[1]','nvarchar(100)') != '10.1.60.81'
	 INSERT INTO IMG_DataServices.dbo.user_login_record
	 (
	  Login_Date
	  ,SPID   
	  ,Server_Name  
	  ,Login_Name  
	  ,Login_Type  
	  ,Login_SID  
	  ,Client_IP 
	  ,Client_Hostname
	  ,Is_Pooled
	 )
	 VALUES 
	 (
	  @eventdata.value('(/EVENT_INSTANCE/PostTime)[1]','datetime2(7)')
	  ,@eventdata.value('(/EVENT_INSTANCE/SPID)[1]','nvarchar(100)')
	  ,@eventdata.value('(/EVENT_INSTANCE/ServerName)[1]','nvarchar(100)')
	  ,@eventdata.value('(/EVENT_INSTANCE/LoginName)[1]','nvarchar(100)')
	  ,@eventdata.value('(/EVENT_INSTANCE/LoginType)[1]','nvarchar(100)')
	  ,@eventdata.value('(/EVENT_INSTANCE/SID)[1]','nvarchar(100)')
	  ,@eventdata.value('(/EVENT_INSTANCE/ClientHost)[1]','nvarchar(100)')
	  ,@hostname
	  ,@eventdata.value('(/EVENT_INSTANCE/IsPooled)[1]','tinyint')
	 )

GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

--DISABLE TRIGGER [User_Login_audit] ON ALL SERVER
GO



--Disable Trigger via DAC

--From a command prompt type in the following (changing the server\instance name accordingly)

--SQLCMD -S COnnection_String –A
--DISABLE TRIGGER User_Login_audit ON ALL SERVER
--GO




-- Create an audit table
CREATE DATABASE AuditDB;
GO
USE AuditDB;
GO
CREATE TABLE LoginAudit
(
    AuditID INT IDENTITY PRIMARY KEY,
    LoginName SYSNAME,
    HostName NVARCHAR(128),
    AppName NVARCHAR(128),
    LoginTime DATETIME DEFAULT GETDATE()
);
GO

-- Logon Trigger
CREATE TRIGGER AuditLogon
ON ALL SERVER
FOR LOGON
AS
BEGIN
    INSERT INTO AuditDB.dbo.LoginAudit(LoginName, HostName, AppName)
    VALUES (ORIGINAL_LOGIN(), HOST_NAME(), APP_NAME());
END;
GO


 
