SELECT
    b.database_name,
    b.backup_start_date,
    b.backup_finish_date,
    b.type AS backup_type,
    b.user_name,
    t.ApplicationName AS program_name,
    t.HostName,
    t.LoginName
FROM msdb.dbo.backupset b
OUTER APPLY
(
    SELECT TOP 1
        ApplicationName,
        HostName,
        LoginName,
        StartTime
    FROM fn_trace_gettable
    (
        (
            SELECT REVERSE(SUBSTRING(REVERSE(path),
            CHARINDEX('\', REVERSE(path)), 260))
            + 'log.trc'
            FROM sys.traces
            WHERE is_default = 1
        ),
        DEFAULT
    ) t
    WHERE t.EventClass = 115 -- Backup/Restore
      AND t.DatabaseName = b.database_name
      AND ABS(DATEDIFF(SECOND, t.StartTime, b.backup_start_date)) < 5
    ORDER BY t.StartTime DESC
) t
ORDER BY b.backup_start_date DESC;
