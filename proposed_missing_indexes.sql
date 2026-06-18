SELECT
    migs.avg_user_impact AS [Avg User Impact],
    mid.database_id AS [Database ID],
    mid.object_id AS [Object ID],
    migs.unique_compiles AS [Unique Compiles],
    migs.user_seeks AS [User Seeks],
    migs.user_scans AS [User Scans],
    migs.avg_total_user_cost AS [Avg Total User Cost],

    (migs.avg_total_user_cost *
     migs.avg_user_impact *
     (migs.user_seeks + migs.user_scans)) AS [Score],

    'CREATE INDEX IX_' +
    OBJECT_NAME(mid.object_id, mid.database_id) + '_' +
    REPLACE(REPLACE(ISNULL(mid.equality_columns,''),', ','_'), '[','') +
    ' ON ' +
    mid.statement +
    ' (' + ISNULL(mid.equality_columns,'') +
    CASE
        WHEN mid.equality_columns IS NOT NULL
             AND mid.inequality_columns IS NOT NULL
        THEN ', '
        ELSE ''
    END +
    ISNULL(mid.inequality_columns,'') + ')' +
    ISNULL(' INCLUDE (' + mid.included_columns + ')','')
    AS [Proposed Index]

FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs
    ON mig.index_group_handle = migs.group_handle
INNER JOIN sys.dm_db_missing_index_details mid
    ON mig.index_handle = mid.index_handle
ORDER BY [Score] DESC;
