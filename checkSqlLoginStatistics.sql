
----Used to check SQL Login Statistics

select   (row_number() over(order by count(distinct sessions.session_id)))%2 as row_num
,       login_name
,       count(distinct sessions.session_id) as session_count
,       count(distinct connections.connection_id) as connection_count
,       count(distinct convert(char,sessions.session_id)+'_'+convert(char,requests.request_id)) as request_count
,       count(distinct cursors.cursor_id) as cursor_count
,       case when sum(requests.open_transaction_count) is null 
                 then 0
                 else  sum(requests.open_transaction_count) 
        end as transaction_count
,       sum(sessions.cpu_time+0.0) as cpu_time
,       sum(sessions.memory_usage * 8) as memory_usage
,       sum(sessions.reads) as reads
,       sum(sessions.writes) as writes
,       max(sessions.last_request_start_time) as last_request_start_time
,       max(sessions.last_request_end_time) as last_request_end_time
from sys.dm_exec_sessions sessions 
left outer join sys.dm_exec_connections connections on sessions.session_id = connections.session_id 
left outer join sys.dm_exec_requests requests on sessions.session_id = requests.session_id 
left outer join sys.dm_exec_cursors(null) cursors on sessions.session_id = cursors.session_id 
where sessions.is_user_process = 1
group by sessions.login_name
order by session_count desc