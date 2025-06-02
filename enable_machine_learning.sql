--The Machine Learning Services feature can be enabled by running the following command:

EXEC sp_configure 'external scripts enabled', 1;
RECONFIGURE WITH OVERRIDE;
