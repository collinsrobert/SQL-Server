use IMG_DataServices
go

/*
*Author: Collins Were
*Date:6/19/2022
*Date modified:     BY: 
*Description:###################################################################################
			 #This procedure is used to activate availability Cluster with popssible data loss## 
			 #in a DR situation ################################################################
             ###################################################################################
*/
create proc sp_failover_availability_cluster_on_DR

as
declare @failover_cluster as varchar(max)

declare failover_cluster_cur cursor for

SELECT 'ALTER AVAILABILITY GROUP ['+Groups.[Name]+'] FORCE_FAILOVER_ALLOW_DATA_LOSS; ' AS AGname
FROM sys.dm_hadr_availability_group_states States
INNER JOIN master.sys.availability_groups Groups ON States.group_id = Groups.group_id

open failover_cluster_cur

fetch next from failover_cluster_cur into @failover_cluster
WHILE @@FETCH_STATUS=0
begin
execute (@failover_cluster)
--print @failover_cluster

fetch next from failover_cluster_cur into @failover_cluster
end
close failover_cluster_cur
deallocate failover_cluster_cur