/***

Author: Collins Robert
Date:
Process SSRS RDL information for easy retrieval
This will provide the following information about SSRS reports
You need to ensure this is being processed from the database server hosting the reports.
This assusmes that the database name is ReportServer

****/

-----####################################################Create Tables below
-----#####################rdl_info_processed
-----#####################
USE [Master]
GO

/****** Object:  Table [dbo].[rdl_info_processed]    Script Date: 9/28/2024 6:33:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[rdl_info_processed](
	[name] [nvarchar](425) NOT NULL,
	[Path] [varchar](200) NOT NULL,
	[Report Description] [varchar](500) NULL,
	[DataSourceName] [varchar](max) NULL,
	[CommandType] [varchar](20) NULL,
	[CommandText] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


-----####################################################Create Tables below
-----#####################rdl_info_master
-----#####################

USE [Master]
GO

/****** Object:  Table [dbo].[rdl_info_master]    Script Date: 9/28/2024 6:39:02 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[rdl_info_master](
	[Name] [nvarchar](425) NOT NULL,
	[Type] [int] NOT NULL,
	[Path] [varchar](200) NOT NULL,
	[TypeDescription] [varchar](14) NOT NULL,
	[Report Description] [varchar](500) NULL,
	[ContentXML] [xml] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


-------------##################Create the SQL Agent Job Below to continuously process the SSRS information and load the two tables above
-------------################## Daily Schedule is alright	

USE [msdb]
GO

/****** Object:  Job [RDL_Infornation_Job]    Script Date: 9/28/2024 6:40:45 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 9/28/2024 6:40:45 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'RDL_Infornation_Job', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Data Services', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Truncate rdl tables]    Script Date: 9/28/2024 6:40:46 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Truncate rdl tables', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'truncate table rdl_info_processed;
truncate table rdl_info_master;', 
		@database_name=N'Master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [load rdl_master]    Script Date: 9/28/2024 6:40:46 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'load rdl_master', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=3, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec Master.dbo.usp_rdl_information', 
		@database_name=N'Master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [process rdl xml]    Script Date: 9/28/2024 6:40:46 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'process rdl xml', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET QUOTED_IDENTIFIER ON
WITH XMLNAMESPACES(DEFAULT ''http://schemas.microsoft.com/sqlserver/reporting/2008/01/reportdefinition'')
insert into  Master.dbo.rdl_info_processed select name,Path,"Report Description",
ContentXML.value(''(/Report/DataSources/DataSource/DataSourceReference/text())[1]'', ''varchar(max)'') DataSourceName
      ,ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandType/text())[1]'', ''varchar(20)'') CommandType
      ,concat(ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[2]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[3]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[4]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[5]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[6]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[7]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[8]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[9]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[10]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[11]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[12]'', ''varchar(max)'')) CommandText
      --,ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)'') CommandText
	    from Master.dbo.rdl_info_master where ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)'') is not null
		go



WITH XMLNAMESPACES( DEFAULT ''http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition'')
insert into  Master.dbo.rdl_info_processed select name,Path,"Report Description",
ContentXML.value(''(/Report/DataSources/DataSource/DataSourceReference/text())[1]'', ''varchar(max)'') DataSourceName
      ,ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandType/text())[1]'', ''varchar(20)'') CommandType
	  ,concat(ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[2]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[3]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[4]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[5]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[6]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[7]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[8]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[9]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[10]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[11]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[12]'', ''varchar(max)'')) CommandText
      --,ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)'') CommandText
	    from Master.dbo.rdl_info_master where ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)'')  is not null
go



WITH XMLNAMESPACES( DEFAULT 		''http://schemas.microsoft.com/sqlserver/reporting/2003/10/reportdefinition'')
insert into  Master.dbo.rdl_info_processed 
select name,Path,"Report Description",
ContentXML.value(''(/Report/DataSources/DataSource/DataSourceReference/text())[1]'', ''varchar(max)'') DataSourceName
      ,ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandType/text())[1]'', ''varchar(20)'') CommandType
	  ,concat(ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[2]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[3]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[4]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[5]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[6]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[7]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[8]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[9]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[10]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[11]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[12]'', ''varchar(max)'')) CommandText
      --,ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)'') CommandText
	    from Master.dbo.rdl_info_master where ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)'')  is not null
go


		WITH XMLNAMESPACES( DEFAULT 		''http://schemas.microsoft.com/sqlserver/reporting/2010/01/reportdefinition'')
insert into  Master.dbo.rdl_info_processed 
select name,Path,"Report Description",
ContentXML.value(''(/Report/DataSources/DataSource/DataSourceReference/text())[1]'', ''varchar(max)'') DataSourceName
      ,ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandType/text())[1]'', ''varchar(20)'') CommandType
	  ,concat(ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[2]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[3]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[4]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[5]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[6]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[7]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[8]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[9]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[10]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[11]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[12]'', ''varchar(max)'')) CommandText
      --,ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)'') CommandText
	    from Master.dbo.rdl_info_master where ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)'')  is not null
		go
WITH XMLNAMESPACES( DEFAULT ''http://schemas.microsoft.com/sqlserver/reporting/2005/01/reportdefinition'')
insert into  Master.dbo.rdl_info_processed  select name,Path,"Report Description",
ContentXML.value(''(/Report/DataSources/DataSource/DataSourceReference/text())[1]'', ''varchar(max)'') DataSourceName
      ,ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandType/text())[1]'', ''varchar(20)'') CommandType
      ,concat(ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[2]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[3]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[4]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[5]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[6]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[7]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[8]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[9]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[10]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[11]'', ''varchar(max)''),'' , '',ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[12]'', ''varchar(max)'')) CommandText
      --,ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)'') CommandText
	    from Master.dbo.rdl_info_master where ContentXML.value(''(/Report/DataSets/DataSet/Query/CommandText/text())[1]'', ''varchar(max)'')  is not null
		go

', 
		@database_name=N'Master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'rdl_schedule_7_am', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180613, 
		@active_end_date=99991231, 
		@active_start_time=70000, 
		@active_end_time=235959, 
		@schedule_uid=N'794e3045-79b8-4ed2-bddc-6ef96619d749'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


