SELECT  session_id ,
request_id ,
percent_complete ,
estimated_completion_time ,
DATEADD(ms,estimated_completion_time,GETDATE()) AS EstimatedEndTime,
start_time ,
status ,
command
FROM sys.dm_exec_requests
