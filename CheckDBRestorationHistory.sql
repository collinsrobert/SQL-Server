

---Use this script to check the database restoration history

use msdb; 
select  (dense_rank() over(order by restore_date desc,  t1.restore_history_id))%2 as l1 
,       (dense_rank() over(order by restore_date desc,  t1.restore_history_id,t2.destination_phys_name))%2 as l2 
,       t1.restore_date
,       t1.destination_database_name
,       t1.user_name
,       t1.restore_type as restore_type
,       t1.replace as [replace]
,       t1.recovery as [recovery]
,       t3.name as backup_name
,       t3.description
,       t3.type as [type]
,       t3.backup_finish_date
,       t3.first_lsn
,       t3.last_lsn
,       t3.differential_base_lsn
,       t2.destination_phys_name 
from restorehistory t1 
left outer join restorefile t2 on ( t1.restore_history_id = t2.restore_history_id ) 
left outer join backupset t3 on ( t1.backup_set_id = t3.backup_set_id ) 
where t1.destination_database_name = 'Staging' ---------------REPLACE DATABASE NAME
order by restore_date desc,  t1.restore_history_id,t2.destination_phys_name 