USE [master]
GO

/****** Object:  StoredProcedure [dbo].[usp_hadr_monitor_availability_health_status]    Script Date: 1/14/2025 2:21:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[usp_hadr_monitor_availability_health_status]
as


/*
*Author: Collins Were
*Date:6/27/2018
*Date modified: 
*Description:################################################################################
			 #This procedure monitors health status of Always On Status.#####################
             #It looks at the Synchronization and Health status of the Secondary Replica's###
			 #Sends aout a nofication to DataServices if the status or not ok ############### 
			 # the last 24 hours.############################################################
			 ###########NULL RECORD ON THE LAST RECIEVED DATA ARE BEING IGNORED FOR NOW#####
*/
declare
@group_name varchar(70),
@replica_server_name varchar(15),
@role_name varchar(30),
@role_desc varchar(30),
@dbs_name varchar(30),
@sync_state varchar(30),
@sync_health varchar(30),
--@DRName varchar(30),
@subj varchar(max),
@message varchar(max),
@counter tinyint;

set @message = '<style type="text/css"> 
    #Header{font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;width:100%;border-collapse:collapse;} 
    #Header td, #Header th {font-size:14px;border:1px solid #a00000;padding:3px 7px 2px 7px;} 
    #Header th {font-size:14px;text-align:left;padding-top:5px;padding-bottom:4px;background-color:#02144c;color:#fff;} 
    #Header tr.alt td {color:#000;background-color:#EAF2D3;} 
    </Style>';
set @message+= '<HTML><BODY><Table border=1 cellpadding=0 cellspacing=0 width=100% id=Header> 
        <TR> 
            <TH><B>Group Name</B></TH> 
            <TH><B>Replica Server Name</B></TD> 
			<TH><B>Role Name</B></TH> 
			<TH><B>Role Description</B></TH> 
            <TH><B>Database Name</B></TH> 
			<TH><B>Synchronization State Desc</B></TH>
			<TH><B>Synchronization Health Desc</B></TH>
					
        </TR>' 

declare hadr_ag_dw_cur CURSOR FOR

select 
	n.group_name
	,n.replica_server_name
	,n.node_name,rs.role_desc
	,db_name(drs.database_id) as database_name
	,drs.synchronization_state_desc
	,drs.synchronization_health_desc 
from sys.dm_hadr_availability_replica_cluster_nodes n 
join sys.dm_hadr_availability_replica_cluster_states cs 
	on n.replica_server_name = cs.replica_server_name 
join sys.dm_hadr_availability_replica_states rs  
	on rs.replica_id = cs.replica_id 
join sys.dm_hadr_database_replica_states drs 
	on rs.replica_id=drs.replica_id 
--where n.replica_server_name <> @@servername


OPEN hadr_ag_dw_cur
fetch next from hadr_ag_dw_cur 
INTO  @group_name, @replica_server_name , @role_name,@role_desc , @dbs_name , @sync_state, @sync_health

while @@FETCH_STATUS = 0
 Begin
 --set @message+= '<TR bgColor=''#ba1d1d''><TD colspan=8 align=left><B>$ServerName</B></TD></TR>';
 if  (@sync_health<>'HEALTHY' or (@sync_state<>'SYNCHRONIZED' AND @sync_state<>'SYNCHRONIZING' ) ) --ADDED @sync_state<>'SYNCHRONIZING' Collins Were 04/11/2019
 Begin
 set @counter=1;
 set @message+='<TR> 
					 <TD>'+@group_name+'</TD> 
                    <TD>'+@replica_server_name+'</TD> 
                    <TD>'+@role_name +'</TD>
					 <TD>'+@role_desc +'</TD>
					<TD>'+@dbs_name +'</TD> 
                    <TD> '+@sync_state +'</TD> 
					<TD>'+@sync_health+'</TD> 
												
               </TR>'
End
		
	
	fetch next from hadr_ag_dw_cur 
INTO   @group_name, @replica_server_name , @role_name,@role_desc , @dbs_name , @sync_state, @sync_health
END

Close hadr_ag_dw_cur;
Deallocate hadr_ag_dw_cur;


if @counter=1
begin
set @subj= 'Avalability group '+@group_name+' Health status '
EXEC msdb.dbo.sp_send_dbmail
@profile_name = 'Default SQL Server Database Mail Profile',
			@recipients = 'example@email.com;',
			@body_format = 'HTML',
			@body =  @message,
		@subject = @subj;
end




GO


