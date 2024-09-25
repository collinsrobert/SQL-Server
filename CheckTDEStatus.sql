/*
It is important to check TDE status before migrating databases. Ultimately, you would want to secure your database at rest by enabling TDE on your databases.

*/
SELECT
DB_NAME(e.database_id) AS DatabaseName,
e.encryption_state,
CASE e.encryption_state
WHEN 0 THEN 'No Database Encryption Key Present, No encryption'
WHEN 1 THEN 'Unencrypted'
WHEN 2 THEN 'Encryption In Progress'
WHEN 3 THEN 'Encrypted'
WHEN 4 THEN 'Key Change In Progress'
WHEN 5 THEN 'Decryption In Progress'
ELSE 'Unknown'
END AS EncryptionStateDesc,
e.percent_complete,
c.name Key_Name,
e.key_algorithm,
e.key_length
FROM sys.dm_database_encryption_keys e
left join master.sys.asymmetric_keys c
on c.thumbprint=e.encryptor_thumbprint
