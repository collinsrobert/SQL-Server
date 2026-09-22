/* =====================================================================
   Script: Generate all database-level and object-level permission 
           statements for the CURRENT database.

   Run this while connected to the database you want to script.
   Output: a result set of executable GRANT/DENY T-SQL statements.
   Copy the "permission_script" column results and run them against
   the target database/server to replicate permissions.
   ===================================================================== */

SET NOCOUNT ON;

------------------------------------------------------------------------
-- 1. DATABASE-LEVEL PERMISSIONS
--    (e.g. CONNECT, CREATE TABLE, ALTER ANY SCHEMA, etc. granted at
--     the database scope, not tied to a specific object)
------------------------------------------------------------------------
SELECT
    'DB_LEVEL' AS permission_scope,
    CASE dp.state
        WHEN 'G' THEN 'GRANT'
        WHEN 'W' THEN 'GRANT'   -- WITH GRANT OPTION handled below
        WHEN 'D' THEN 'DENY'
        WHEN 'R' THEN 'REVOKE'
    END
    + ' ' + dp.permission_name COLLATE DATABASE_DEFAULT
    + ' TO [' + dpr.name COLLATE DATABASE_DEFAULT + ']'
    + CASE WHEN dp.state = 'W' THEN ' WITH GRANT OPTION' ELSE '' END
    + ';' AS permission_script
FROM sys.database_permissions dp
JOIN sys.database_principals dpr
    ON dp.grantee_principal_id = dpr.principal_id
WHERE dp.major_id = 0   -- major_id = 0 => database-level (not object-scoped)
ORDER BY dpr.name, dp.permission_name;


------------------------------------------------------------------------
-- 2. OBJECT-LEVEL PERMISSIONS
--    (permissions on tables, views, stored procedures, functions, 
--     synonyms, etc. — includes column-level grants too)
------------------------------------------------------------------------
SELECT
    'OBJECT_LEVEL' AS permission_scope,
    CASE dp.state
        WHEN 'G' THEN 'GRANT'
        WHEN 'W' THEN 'GRANT'
        WHEN 'D' THEN 'DENY'
        WHEN 'R' THEN 'REVOKE'
    END
    + ' ' + dp.permission_name COLLATE DATABASE_DEFAULT
    -- include column name if this is a column-level grant
    + CASE WHEN dp.minor_id <> 0 
           THEN ' (' + c.name COLLATE DATABASE_DEFAULT + ')' 
           ELSE '' 
      END
    + ' ON [' + s.name COLLATE DATABASE_DEFAULT + '].[' + o.name COLLATE DATABASE_DEFAULT + ']'
    + ' TO [' + dpr.name COLLATE DATABASE_DEFAULT + ']'
    + CASE WHEN dp.state = 'W' THEN ' WITH GRANT OPTION' ELSE '' END
    + ';' AS permission_script
FROM sys.database_permissions dp
JOIN sys.database_principals dpr
    ON dp.grantee_principal_id = dpr.principal_id
JOIN sys.objects o
    ON dp.major_id = o.object_id
JOIN sys.schemas s
    ON o.schema_id = s.schema_id
LEFT JOIN sys.columns c
    ON dp.major_id = c.object_id
   AND dp.minor_id = c.column_id
WHERE dp.class = 1   -- class 1 = objects/columns
ORDER BY s.name, o.name, dpr.name;


------------------------------------------------------------------------
-- 3. SCHEMA-LEVEL PERMISSIONS
--    (e.g. GRANT SELECT ON SCHEMA::dbo TO SomeUser)
------------------------------------------------------------------------
SELECT
    'SCHEMA_LEVEL' AS permission_scope,
    CASE dp.state
        WHEN 'G' THEN 'GRANT'
        WHEN 'W' THEN 'GRANT'
        WHEN 'D' THEN 'DENY'
        WHEN 'R' THEN 'REVOKE'
    END
    + ' ' + dp.permission_name COLLATE DATABASE_DEFAULT
    + ' ON SCHEMA::[' + s.name COLLATE DATABASE_DEFAULT + ']'
    + ' TO [' + dpr.name COLLATE DATABASE_DEFAULT + ']'
    + CASE WHEN dp.state = 'W' THEN ' WITH GRANT OPTION' ELSE '' END
    + ';' AS permission_script
FROM sys.database_permissions dp
JOIN sys.database_principals dpr
    ON dp.grantee_principal_id = dpr.principal_id
JOIN sys.schemas s
    ON dp.major_id = s.schema_id
WHERE dp.class = 3   -- class 3 = schema
ORDER BY s.name, dpr.name;


------------------------------------------------------------------------
-- 4. DATABASE ROLE MEMBERSHIPS
--    (which users/logins belong to which database roles, e.g. 
--     db_datareader, db_datawriter, custom roles)
------------------------------------------------------------------------
SELECT
    'ROLE_MEMBERSHIP' AS permission_scope,
    'ALTER ROLE [' + roles.name COLLATE DATABASE_DEFAULT + '] ADD MEMBER [' 
        + members.name COLLATE DATABASE_DEFAULT + '];' AS permission_script
FROM sys.database_role_members drm
JOIN sys.database_principals roles
    ON drm.role_principal_id = roles.principal_id
JOIN sys.database_principals members
    ON drm.member_principal_id = members.principal_id
ORDER BY roles.name, members.name;


------------------------------------------------------------------------
-- 5. SERVER-LEVEL PERMISSIONS (run only if connected with sufficient
--    rights; these apply server-wide, not per-database)
--    Uncomment to include logins' server-level grants (e.g. 
--    CONNECT SQL, VIEW SERVER STATE, sysadmin membership, etc.)
------------------------------------------------------------------------
/*
SELECT
    'SERVER_LEVEL' AS permission_scope,
    CASE sp.state
        WHEN 'G' THEN 'GRANT'
        WHEN 'W' THEN 'GRANT'
        WHEN 'D' THEN 'DENY'
        WHEN 'R' THEN 'REVOKE'
    END
    + ' ' + sp.permission_name COLLATE DATABASE_DEFAULT
    + ' TO [' + spr.name COLLATE DATABASE_DEFAULT + ']'
    + CASE WHEN sp.state = 'W' THEN ' WITH GRANT OPTION' ELSE '' END
    + ';' AS permission_script
FROM sys.server_permissions sp
JOIN sys.server_principals spr
    ON sp.grantee_principal_id = spr.principal_id
WHERE spr.type IN ('S','U','G')  -- SQL login, Windows login, Windows group
ORDER BY spr.name, sp.permission_name;
*/

/* =====================================================================
   NOTES
   -----
   - dp.state meanings: G = Grant, W = Grant_With_Grant_Option, 
     D = Deny, R = Revoke (Revoke rows normally won't appear since 
     revoked permissions aren't stored as active rows).
   - This script only covers permissions GRANTED DIRECTLY. It does not
     resolve effective/inherited permissions coming purely from role 
     membership (those are covered separately by the role-membership 
     section above — combine both to get the full picture).
   - Principals must already exist in the TARGET database/server before 
     running the generated GRANT statements there (create logins/users 
     first if scripting to a new environment).
   - For a full environment migration, also script out the logins 
     themselves (sp_help_revlogin or equivalent) separately, since 
     this script only covers users/roles that already exist within 
     the current database.
   ===================================================================== */
