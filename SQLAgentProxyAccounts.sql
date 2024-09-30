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
-------Below is a sample job executing SSAS cube and running as SSAS_Proxy proxy account sample we created above


USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'SSAS_Cube_Processing_Job', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'SSAS_Cube_Processing_Job', @server_name = N'SPV-SDW01'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'SSAS_Cube_Processing_Job', @step_name=N'Process cube', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'ANALYSISCOMMAND', 
		@command=N'<Process xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
  <Type>ProcessFull</Type>
  <Object>
    <DatabaseID>90Day_Sales</DatabaseID>
  </Object>
</Process>', 
		@server=N'ssas_servername', ---------------------insert the correct server name here
		@database_name=N'master', 
		@flags=0, 
		@proxy_name=N'SSAS_Proxy'---------------------------specify the job step to be executed using the SSAS_Proxy proxy account. This account should have the privilege need on the remote server to execute the step
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'SSAS_Cube_Processing_Job', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'[SSAS Category]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO

