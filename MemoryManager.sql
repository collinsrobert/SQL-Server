 
                select  object_name
                ,       counter_name
                ,       convert(varchar(10),cntr_value) as cntr_value
                from sys.dm_os_performance_counters
                where ( 
				(object_name like '%Manager%') and (counter_name = 'Memory Grants Pending' or counter_name='Memory Grants Outstanding' or counter_name = 'Page life expectancy' /*or counter_name = 'Stolen pages'*/ ))
            




                declare @table1 table(
                objecttype varchar (100) collate database_default
                ,       buffers bigint
                );

                insert @table1
                exec('dbcc memorystatus with tableresults')

                select 
                     objecttype
                ,       buffers as value
             
                from @table1
                where objecttype in ('Stolen','Free','Cached','Dirty','Kept','I/O','Latched','Other','DirtyPageTracking','Locks','Page Life Expectancy' )
             
         
  
