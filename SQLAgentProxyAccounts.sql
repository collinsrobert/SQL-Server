/****************
Author: Collins Robert
Description: All you need to know about proxy accounts.

A SQL Server Agent proxy account defines a security context in which a job step can run. 
Each proxy corresponds to a security credential. To set permissions for a particular job step, 
create a proxy that has the required permissions for a SQL Server Agent subsystem, and then assign that proxy to the job step. 
(Adopted from Microsoft)

*****************/

----Create a credential using script below
IF EXISTS(
  SELECT * 
    FROM sys.credentials 
   WHERE name = N'ACTIVE_DIRECTORY\ProxyAccunt'
)
DROP CREDENTIAL [ACTIVE_DIRECTORY\ProxyAccunt]
GO

CREATE CREDENTIAL [ACTIVE_DIRECTORY\ProxyAccunt]----This can be any name
	WITH IDENTITY = N'ACTIVE_DIRECTORY\ProxyAccunt', 
	SECRET = N'12345'---This references the password of the credential
	
GO
