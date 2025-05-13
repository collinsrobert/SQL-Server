 
                select  object_name
                ,       counter_name
                ,       convert(varchar(10),cntr_value) as cntr_value
                from sys.dm_os_performance_counters
                where ( 
				(object_name like '%Manager%') and (counter_name = 'Memory Grants Pending' or counter_name='Memory Grants Outstanding' ))
            
