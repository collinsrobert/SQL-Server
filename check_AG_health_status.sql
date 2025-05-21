SELECT db_name(database_id), synchronization_state_desc,synchronization_health_desc is_suspended, suspend_reason_desc
FROM sys.dm_hadr_database_replica_states
WHERE db_name(database_id) = 'DB';
