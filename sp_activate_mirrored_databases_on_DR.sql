use IMG_DataServices
go

create proc sp_activate_mirrored_databases_on_DR

as

/*
*Author: Collins Were
*Date:4/24/2022
*Date modified:     BY: 
*Description:###################################################################################
			 #This procedure is used to activate mirrored databases in the event of a DR.#######
             ###################################################################################
*/
declare @sql_recover as varchar(max);
declare @sql_partner as varchar(max);


--Set the database partners OFF
declare sql_partner_cur cursor for


select 'alter database ['+name+'] set partner OFF' from sys.databases  where state_desc='restoring'

open sql_partner_cur
fetch next from sql_partner_cur
into @sql_partner

WHILE @@FETCH_STATUS = 0  
BEGIN  
exec (@sql_partner)--Set the partner OFF

--print @sql_partner

fetch next from sql_partner_cur
into @sql_partner
END
close sql_partner_cur
deallocate sql_partner_cur

---Restore The databases with RECOVERY
declare sql_recover_cur cursor for


select 'restore database ['+name+'] with recovery' from sys.databases  where state_desc='restoring'


open sql_recover_cur
fetch next from sql_recover_cur
into @sql_recover

WHILE @@FETCH_STATUS = 0  
BEGIN 

exec (@sql_recover)--Restore database and bring it online ready for connection

----print @sql_recover


fetch next from sql_recover_cur
into @sql_partner
END
close sql_recover_cur
deallocate sql_recover_cur