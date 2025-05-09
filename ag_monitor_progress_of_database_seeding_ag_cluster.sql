--AG sync status 

--This script needs to be run in SQLCMD mode in SSMS

:setvar PRIMARY primaryserver

:setvar SECONDARY secondaryserver

-- monitor restore progrss on secondary

:connect $(SECONDARY)

SELECT

r.session_id, r.status, r.command, r.wait_type

, r.percent_complete, r.estimated_completion_time, r.*

FROM sys.dm_exec_requests r JOIN sys.dm_exec_sessions s

ON r.session_id = s.session_id

WHERE r.session_id <> @@SPID

AND s.is_user_process = 0

AND r.command like 'VDI%'

and wait_type ='BACKUPTHREAD'

go

-- monitor seeding queue on primary

:connect $(PRIMARY)

SELECT DB_NAME(rs.database_id) as DatabaseName, rs.is_primary_replica, rs.is_local, rs.synchronization_health_desc, rs.synchronization_state_desc, rs.is_suspended

      ,s.current_state

      ,s.performed_seeding

      ,s.number_of_attempts

      ,s.failure_state_desc

      ,s.completion_time

      ,rs.last_sent_time

      ,rs.last_sent_time

      ,rs.last_received_time

      ,rs.last_hardened_time

      ,rs.last_redone_time

      ,s.ag_id, s.ag_db_id

FROM sys.dm_hadr_database_replica_states rs

JOIN sys.availability_databases_cluster as adb ON adb.group_database_id = rs.group_database_id

join sys.dm_hadr_automatic_seeding s ON s.ag_db_id = adb.group_database_id

WHERE rs.synchronization_state_desc not in ( 'SYNCHRONIZED', 'SYNCHRONIZING' )

and s.completion_time is null

order by s.start_time

go
 
