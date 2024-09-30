/****************
Author: Collins Robert
Description: All you need to know about proxy accounts.

A SQL Server Agent proxy account defines a security context in which a job step can run. 
Each proxy corresponds to a security credential. To set permissions for a particular job step, 
create a proxy that has the required permissions for a SQL Server Agent subsystem, and then assign that proxy to the job step. 
(Adopted from Microsoft)

*****************/

----Create a credential using script below
IF EXISTS(
  SELECT * 
    FROM sys.credentials 
   WHERE name = N'ACTIVE_DIRECTORY\ProxyAccunt'
)
DROP CREDENTIAL [ACTIVE_DIRECTORY\ProxyAccunt]
GO

CREATE CREDENTIAL [ACTIVE_DIRECTORY\ProxyAccunt]----This can be any name
	WITH IDENTITY = N'ACTIVE_DIRECTORY\ProxyAccunt', 
	SECRET = N'12345'---This references the password of the credential
	
GO


---Then create a proxy associated to the credential above using the script below
---You will need to create all needed proxies
--Commonly used proxies
/********************
Operating System (CmdExec)
PowerShell
SSIS Package Execution
Analysis Services Command
*********************/
--++++++++++++++++++=====================================================================================================
---below is Operating System (CmdExec)
	--This can be used to execute ane batch scripts or any command that can be called from cmd or Dos  locally or remotely
USE [msdb]
GO
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'CMD_Proxy',@credential_name=N'ACTIVE_DIRECTORY\ProxyAccunt', 
		@enabled=1
GO
EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'CMD_Proxy', @subsystem_id=3
GO


--++++++++++++++++++=====================================================================================================
---below is Analysis Services Command
	---This can be used to run SSAS Cubes when connected to an SSAS engine  locally or remotely


USE [msdb]
GO
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'SSAS_Proxy',@credential_name=N'ACTIVE_DIRECTORY\ProxyAccunt', 
		@enabled=1
GO
EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'SSAS_Proxy', @subsystem_id=10
GO


--++++++++++++++++++=====================================================================================================
---below is Analysis Services Command
	---This can be used to run SSIS packages when connected to an SSIS Integration catalog  locally or remotely

USE [msdb]
GO
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'SSIS_proxy',@credential_name=N'ACTIVE_DIRECTORY\ProxyAccunt', 
		@enabled=1
GO
EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'SSIS_proxy', @subsystem_id=11
GO



--++++++++++++++++++=====================================================================================================
---below is Analysis Services Command
	---This can be used to run powershell scripts locally or remotely
USE [msdb]
GO
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'PowerShell_Proxy',@credential_name=N'ACTIVE_DIRECTORY\ProxyAccunt', 
		@enabled=1
GO
EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'PowerShell_Proxy', @subsystem_id=12
GO

--------------Once you create the proxy account, you can then use it when defining a SQL Agent Job Step.

