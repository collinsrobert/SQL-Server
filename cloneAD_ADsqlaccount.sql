/*===========================================================================
   CLONE SQL SERVER LOGIN PERMISSIONS (AD → AD)

   Copies:
     - Creates login if missing
     - Server roles
     - Server permissions
     - Database users
     - Database roles
     - Database object/schema/database permissions

   Run as sysadmin/securityadmin
===========================================================================*/

SET NOCOUNT ON;

DECLARE @SourceLogin sysname = N'domain\clonefrom';
DECLARE @TargetLogin sysname = N'domain\cloneto';

DECLARE @SQL nvarchar(max);

---------------------------------------------------------------------------
-- 1. Ensure Target Login Exists
---------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @TargetLogin)
BEGIN
    PRINT 'Creating login: ' + @TargetLogin;
    SET @SQL = N'CREATE LOGIN ' + QUOTENAME(@TargetLogin) + N' FROM WINDOWS;';
    EXEC sys.sp_executesql @SQL;
END
ELSE
    PRINT 'Target login already exists.';

---------------------------------------------------------------------------
-- 2. Copy Server Role Memberships
---------------------------------------------------------------------------
PRINT 'Copying server role memberships...';

SELECT @SQL =
(
    SELECT STRING_AGG(
        'ALTER SERVER ROLE ' + QUOTENAME(r.name) +
        ' ADD MEMBER ' + QUOTENAME(@TargetLogin) + ';'
    , CHAR(10))
    FROM sys.server_role_members rm
    JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
    JOIN sys.server_principals u ON rm.member_principal_id = u.principal_id
    WHERE u.name = @SourceLogin
);

IF @SQL IS NOT NULL
    EXEC sys.sp_executesql @SQL;

---------------------------------------------------------------------------
-- 3. Copy Server Permissions
---------------------------------------------------------------------------
PRINT 'Copying server permissions...';

SELECT @SQL =
(
    SELECT STRING_AGG(
        CASE perm.state_desc
            WHEN 'GRANT_WITH_GRANT_OPTION'
                THEN 'GRANT ' + perm.permission_name +
                     ' TO ' + QUOTENAME(@TargetLogin) + ' WITH GRANT OPTION;'
            WHEN 'GRANT'
                THEN 'GRANT ' + perm.permission_name +
                     ' TO ' + QUOTENAME(@TargetLogin) + ';'
            WHEN 'DENY'
                THEN 'DENY ' + perm.permission_name +
                     ' TO ' + QUOTENAME(@TargetLogin) + ';'
        END
    , CHAR(10))
    FROM sys.server_permissions perm
    JOIN sys.server_principals u ON perm.grantee_principal_id = u.principal_id
    WHERE u.name = @SourceLogin
);

IF @SQL IS NOT NULL
    EXEC sys.sp_executesql @SQL;

---------------------------------------------------------------------------
-- 4. Copy Database Users + Roles + Permissions
---------------------------------------------------------------------------
PRINT 'Copying database-level permissions...';

DECLARE @DB sysname;

DECLARE DB_CURSOR CURSOR FOR
SELECT name
FROM sys.databases
WHERE database_id > 4
  AND state_desc = 'ONLINE';

OPEN DB_CURSOR;
FETCH NEXT FROM DB_CURSOR INTO @DB;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Processing DB: ' + @DB;

    SET @SQL = N'
    USE ' + QUOTENAME(@DB) + N';

    -- Skip if source user not in DB
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @SourceLogin)
        RETURN;

    -- Create target user if missing
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @TargetLogin)
        EXEC(''CREATE USER ' + QUOTENAME(@TargetLogin) + ' FOR LOGIN ' + QUOTENAME(@TargetLogin) + ';'');

    ------------------------------------------------------------
    -- Copy DB Role Memberships
    ------------------------------------------------------------
    DECLARE @CMD nvarchar(max) = N''''

    SELECT @CMD +=
        ''ALTER ROLE '' + QUOTENAME(r.name) +
        '' ADD MEMBER '' + QUOTENAME(@TargetLogin) + '';'' + CHAR(10)
    FROM sys.database_role_members rm
    JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
    JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id
    WHERE u.name = @SourceLogin;

    EXEC(@CMD);

    ------------------------------------------------------------
    -- Copy Explicit Permissions
    ------------------------------------------------------------
    SET @CMD = N''''

    SELECT @CMD +=
        CASE dp.state_desc
            WHEN ''GRANT'' THEN
                ''GRANT '' + dp.permission_name +
                '' TO '' + QUOTENAME(@TargetLogin) + '';''

            WHEN ''DENY'' THEN
                ''DENY '' + dp.permission_name +
                '' TO '' + QUOTENAME(@TargetLogin) + '';''

            WHEN ''GRANT_WITH_GRANT_OPTION'' THEN
                ''GRANT '' + dp.permission_name +
                '' TO '' + QUOTENAME(@TargetLogin) +
                '' WITH GRANT OPTION;''
        END + CHAR(10)
    FROM sys.database_permissions dp
    JOIN sys.database_principals u ON dp.grantee_principal_id = u.principal_id
    WHERE u.name = @SourceLogin;

    EXEC(@CMD);
    ';

    EXEC sys.sp_executesql
        @SQL,
        N'@SourceLogin sysname, @TargetLogin sysname',
        @SourceLogin=@SourceLogin,
        @TargetLogin=@TargetLogin;

    FETCH NEXT FROM DB_CURSOR INTO @DB;
END

CLOSE DB_CURSOR;
DEALLOCATE DB_CURSOR;

PRINT 'CLONE COMPLETE'
