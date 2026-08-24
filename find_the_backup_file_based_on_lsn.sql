
SELECT
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.first_lsn,
    bs.last_lsn,
    bs.database_backup_lsn,
    bmf.physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = N'DatabseName'
  AND bs.type = 'L'
  and last_lsn>='504633000003012000001'--504633000003012000001
ORDER BY bs.first_lsn;
