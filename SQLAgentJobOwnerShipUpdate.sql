/***********************
Author: Collins Robert
Description: The script below updates the SQL Agent Job owner to the sa account.
              It generates a report of the ownership prior to the update and a validation that 
              the update has been susccesfully completed
Date Created: 2024/10/01

************************/



use msdb
go

---Check job owner before update

select name, suser_sname(owner_sid) OwnerBeforeUpdate from msdb.dbo.sysjobs

--Update owner to sa
declare @command varchar(max)

declare sqlagent_sa_update CURSOR for
select 'EXEC msdb.dbo.sp_update_job @job_id=N'''+cast(job_id as varchar(max))+''',@owner_login_name=N''sa''' from msdb.dbo.sysjobs

open sqlagent_sa_update
fetch next from sqlagent_sa_update
into @command

while @@FETCH_STATUS=0
Begin
--print @command
exec(@command)

fetch next from sqlagent_sa_update
into @command

end

close sqlagent_sa_update
deallocate sqlagent_sa_update

---Check job owner After update

select name, suser_sname(owner_sid) OwnerAfterUpdate from msdb.dbo.sysjobs


