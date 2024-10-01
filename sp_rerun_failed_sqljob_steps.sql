--Author: Collins Robert
--Create Date: 9/23/2024
	---These scripts will work provided the database mail has already been configured , tested and enabled .
--- Also provided the SQL agent notification properties has been configured with the correct database mail profile.
----Create notification log table

USE [Master]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[dataservices_notifications_log](
	[Notification_Id] [int] IDENTITY(1,1) NOT NULL,
	[Message] [varchar](50) NULL,
	[Last_Sent] [datetime] NULL
) ON [PRIMARY]
GO






Use Master
go
Create proc sp_rerun_failed_sqljob_steps
/*
Author: Collins Robert
Create Date: 9/23/2024
************Description: This procedure re-runs any failed job step that occured within the last hour, 
************************provided the job is not retrying or re-executing. It then sends out an email showing the originating server name,
************************the sql agent step error message, the re-execution command showing which job and step is re-running and the details of the step being executed. 	
*/
as
begin

declare @sql varchar(max),
@subj varchar(max),
@message varchar(max),
@msg varchar(max),
@profile varchar(max),
@email 	varchar(max) ='email@example.com;'-----<---- replace the correct email address or email distribution right HERE
@command varchar(max);

--------------------#########################Retrieve the email profile define on SQL server Agent for notifications and/or alerts
--------------------#########################Added 2024/09/29 

declare @dirtable table ([value] varchar(max),
[Data] varchar(max) ) 
insert into @dirtable
exec master.dbo.xp_instance_regread  N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'DatabaseMailProfile'
select @profile=[Data] from @dirtable

---print @profile

declare sql_jobstep_fail_rerun_cur CURSOR FOR


select max(jh.message) StepMessage , max('EXEC msdb.dbo.sp_start_job @job_name=N'''+j.name+''',  @step_name='''+js.step_name+'''') as sql_jobstep, max(js.command) StepDetails
from msdb.dbo.sysjobsteps js join msdb.dbo.sysjobs j on j.job_id=js.job_id
join msdb.dbo.sysjobhistory jh on jh.step_name=js.step_name
join msdb.dbo.sysjobactivity ja on j.job_id=ja.job_id
where js.last_run_outcome=0 and js.last_run_date<>0 and 
CAST(
STUFF(STUFF(CAST(js.last_run_date as varchar),7,0,'-'),5,0,'-') + ' ' + 
STUFF(STUFF(REPLACE(STR(js.last_run_time,6,0),' ','0'),5,0,':'),3,0,':') as datetime)>=dateadd(MINUTE,-60,getdate())
and ja.start_execution_date IS NOT NULL
   AND ja.stop_execution_date IS not NULL

open sql_jobstep_fail_rerun_cur


fetch next from sql_jobstep_fail_rerun_cur 
INTO @message,@sql,@command

while @@FETCH_STATUS = 0
 Begin

 if  (@sql is not null)
 Begin
 exec(@sql)


	
 select @profile= max(name)
from msdb.dbo.sysmail_profile 



	
 set @msg='<style> 
 H1 {color:blue;text-align:center;background-color:Maroon;padding-top:5px;padding-bottom:4px; }
  </Style> <body><H1>ServerName</H1></BR><span style="background-color:yellow;">'+cast(@@servername as varchar(max))+'</span><H1>Failure message</H1></BR> <span style="background-color:red;">'+@message+'</span></BR> <H1>SQL Job Restarted below</H1></BR>'+@sql+'</BR> <H1 >Step Details executed below</H1></BR>'+@command+'</br></body>'

 set @subj= 'SQL Server Failed JobStep Has been re-started'
				EXEC msdb.dbo.sp_send_dbmail
				@profile_name = @profile,
							@recipients = @email,
							@body_format = 'HTML',
							@body =  @msg,
						@subject = @subj;
						
						insert into [Master].[dbo].[dataservices_notifications_log]("Message",Last_Sent) values('SQL Server Failed Jobs Step restarted',getdate());
	END					

 fetch next from sql_jobstep_fail_rerun_cur 
INTO  @message,  @sql,@command
END

Close sql_jobstep_fail_rerun_cur;
Deallocate sql_jobstep_fail_rerun_cur;

end---end or proc

----Create job to execute above script every 30 mins
---------###########################################################SQL AGENT JOB Below


USE [msdb]
GO

/****** Object:  Job [rerun_failed_sqljob_steps]    Script Date: 9/27/2024 5:19:53 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 9/27/2024 5:19:53 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'rerun_failed_sqljob_steps', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [[sp_rerun_failed_sqljob_steps]]    Script Date: 9/27/2024 5:19:54 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'[sp_rerun_failed_sqljob_steps]', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Exec [sp_rerun_failed_sqljob_steps]', 
		@database_name=N'Master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'30min Schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20240927, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'ac3d424b-7553-4d7e-bc78-77ea039a9b56'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



