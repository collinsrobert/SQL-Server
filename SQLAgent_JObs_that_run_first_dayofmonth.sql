SELECT
    j.name AS JobName,
    s.name AS ScheduleName,
    CASE s.freq_type
        WHEN 1 THEN 'One Time'
        WHEN 4 THEN 'Daily'
        WHEN 8 THEN 'Weekly'
        WHEN 16 THEN 'Monthly (Day)'
        WHEN 32 THEN 'Monthly (Relative)'
        WHEN 64 THEN 'When SQL Server Agent starts'
        WHEN 128 THEN 'Idle'
    END AS ScheduleType,
    s.freq_recurrence_factor AS RecurrenceFactor,
    s.freq_interval AS IntervalDayOfMonth
FROM
    msdb.dbo.sysjobs j
INNER JOIN
    msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
INNER JOIN
    msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
WHERE
    s.freq_type = 16 -- Monthly (Day)
    AND s.freq_interval = 1; -- First day of the month
