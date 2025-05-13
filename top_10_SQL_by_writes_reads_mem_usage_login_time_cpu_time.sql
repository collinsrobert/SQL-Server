-----------By READS


                select top 10 s.session_id
                ,       s.login_time
                ,       s.host_name
                ,       s.program_name
                ,       s.cpu_time as cpu_time
                ,       s.memory_usage * 8 as memory_usage
                ,       s.total_scheduled_time as total_scheduled_time
                ,       s.total_elapsed_time as total_elapsed_time
                ,       s.last_request_end_time
                ,       s.reads
                ,       s.writes
                ,       count(c.connection_id) as conn_count
                from sys.dm_exec_sessions s
                left outer join sys.dm_exec_connections c  on ( s.session_id = c.session_id )
                left outer join sys.dm_exec_requests r  on ( r.session_id = c.session_id )
                where (s.is_user_process= 1)
                group by s.session_id, s.login_time, s.host_name, s.cpu_time, s.memory_usage, s.total_scheduled_time, s.total_elapsed_time, s.last_request_end_time, s.reads, s.writes, s.program_name
                order by s.reads  desc


------BY WRITES



                select top 10 s.session_id
                ,       s.login_time
                ,       s.host_name
                ,       s.program_name
                ,       s.cpu_time as cpu_time
                ,       s.memory_usage * 8 as memory_usage
                ,       s.total_scheduled_time as total_scheduled_time
                ,       s.total_elapsed_time as total_elapsed_time
                ,       s.last_request_end_time
                ,       s.reads
                ,       s.writes
                ,       count(c.connection_id) as conn_count
                from sys.dm_exec_sessions s
                left outer join sys.dm_exec_connections c  on ( s.session_id = c.session_id )
                left outer join sys.dm_exec_requests r  on ( r.session_id = c.session_id )
                where (s.is_user_process= 1)
                group by s.session_id, s.login_time, s.host_name, s.cpu_time, s.memory_usage, s.total_scheduled_time, s.total_elapsed_time, s.last_request_end_time, s.reads, s.writes, s.program_name
                order by s.writes  desc
-------MEMORY USAGE



                select top 10 s.session_id
                ,       s.login_time
                ,       s.host_name
                ,       s.program_name
                ,       s.cpu_time as cpu_time
                ,       s.memory_usage * 8 as memory_usage
                ,       s.total_scheduled_time as total_scheduled_time
                ,       s.total_elapsed_time as total_elapsed_time
                ,       s.last_request_end_time
                ,       s.reads
                ,       s.writes
                ,       count(c.connection_id) as conn_count
                from sys.dm_exec_sessions s
                left outer join sys.dm_exec_connections c  on ( s.session_id = c.session_id )
                left outer join sys.dm_exec_requests r  on ( r.session_id = c.session_id )
                where (s.is_user_process= 1)
                group by s.session_id, s.login_time, s.host_name, s.cpu_time, s.memory_usage, s.total_scheduled_time, s.total_elapsed_time, s.last_request_end_time, s.reads, s.writes, s.program_name
                order by s.memory_usage  desc

  ----------BY LOGIN TIME




                select top 10 s.session_id
                ,       s.login_time
                ,       s.host_name
                ,       s.program_name
                ,       s.cpu_time as cpu_time
                ,       s.memory_usage * 8 as memory_usage
                ,       s.total_scheduled_time as total_scheduled_time
                ,       s.total_elapsed_time as total_elapsed_time
                ,       s.last_request_end_time
                ,       s.reads
                ,       s.writes
                ,       count(c.connection_id) as conn_count
                from sys.dm_exec_sessions s
                left outer join sys.dm_exec_connections c  on ( s.session_id = c.session_id )
                left outer join sys.dm_exec_requests r  on ( r.session_id = c.session_id )
                where (s.is_user_process= 1)
                group by s.session_id, s.login_time, s.host_name, s.cpu_time, s.memory_usage, s.total_scheduled_time, s.total_elapsed_time, s.last_request_end_time, s.reads, s.writes, s.program_name
                order by s.login_time  desc


------BY CPU TIME


                select top 10 s.session_id
                ,       s.login_time
                ,       s.host_name
                ,       s.program_name
                ,       s.cpu_time as cpu_time
                ,       s.memory_usage * 8 as memory_usage
                ,       s.total_scheduled_time as total_scheduled_time
                ,       s.total_elapsed_time as total_elapsed_time
                ,       s.last_request_end_time
                ,       s.reads
                ,       s.writes
                ,       count(c.connection_id) as conn_count
                from sys.dm_exec_sessions s
                left outer join sys.dm_exec_connections c  on ( s.session_id = c.session_id )
                left outer join sys.dm_exec_requests r  on ( r.session_id = c.session_id )
                where (s.is_user_process= 1)
                group by s.session_id, s.login_time, s.host_name, s.cpu_time, s.memory_usage, s.total_scheduled_time, s.total_elapsed_time, s.last_request_end_time, s.reads, s.writes, s.program_name
                order by s.cpu_time  desc

  
         
  
