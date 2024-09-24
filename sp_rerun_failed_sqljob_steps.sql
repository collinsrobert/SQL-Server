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

declare @sql varchar(max),
@subj varchar(max),
@message varchar(max),
@msg varchar(max),
@profile varchar(max),
@command varchar(max);

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
							@recipients = 'email@email.com;',
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


