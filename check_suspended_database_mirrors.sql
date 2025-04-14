select 'ALTER DATABASE ['+
 db.name+'] SET PARTNER RESUME' ,
 db.state_desc, 
 dm.mirroring_role_desc, 
 dm.mirroring_state_desc,
 dm.mirroring_safety_level_desc,
 dm.mirroring_partner_name, 
 dm.mirroring_partner_instance 
from sys.databases db
inner join sys.database_mirroring dm
on db.database_id = dm.database_id
where dm.mirroring_role_desc ='SUSPENDED'
