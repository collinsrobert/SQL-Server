SELECT
    --execution_id,
     folder_name,
project_name,
package_name,
    status,
cast(start_time as date) StartTime,
    end_time,
    DATEDIFF(SECOND, start_time, ISNULL(end_time, GETDATE())) AS duration_seconds
FROM SSISDB.catalog.executions

--where package_name='insert_package_name_here'
ORDER BY start_time DESC;
