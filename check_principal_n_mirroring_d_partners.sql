select distinct @@servername Principal_Partner_Name,mirroring_partner_name,mirroring_partner_instance 
from sys.database_mirroring where mirroring_partner_instance is not null
