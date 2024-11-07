--When you start encrypting \ Decrypting a SQL Server Database by issuing the following commands

ALTER DATABASE DB_NAME SET ENCRYPTION ON  -------Encrypt  TDE
--OR

ALTER DATABASE DB_NAME SET ENCRYPTION OFF -------Decrypt TDE 


---Then the executions above start impacting performance in the database server. You can pause them by issuing the following commands

DBCC TRACEON(5004,-1)  ---this will pause the TDE scan process
DBCC TRACEOFF(5004,-1)  ---this will unpause the TDE scan process but, you will need to execute the commands above to start the encryption\decryption process again.
