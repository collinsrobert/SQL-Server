/********************************
Author: Collins Robert
SQL Agent may appear disabled on SQL Server installed on linux server
Run script below to enable SQL Agent and get it started.

*******************************/


EXEC sp_configure 'show advanced options', 1;
RECONFIGURE WITH OVERRIDE;
EXEC sp_configure 'Agent XPs', 1;
RECONFIGURE WITH OVERRIDE;
