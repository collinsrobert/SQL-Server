---#########Run this script to generate a SQL script for disabling CDC on sql server per table requested

SELECT 'EXEC sys.sp_cdc_disable_table   @source_schema = N'''+s.name+''', @source_name = N'''+t.name+''',@capture_instance =N'''+ c.capture_instance+'''',
    t.name AS TableName,
    s.name AS SchemaName,
    c.capture_instance AS ResourceName
FROM 
    sys.tables t
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    cdc.change_tables c ON t.object_id = c.source_object_id;



