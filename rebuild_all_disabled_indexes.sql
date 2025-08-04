-- replace SCHEMA_NAME with your schema

SELECT 
    t.name AS TableName,
    i.name AS IndexName,
	i.is_disabled,
	i.type_desc,
	'alter index ['+i.name+'] ON SCHEMA_NAME.'+t.name +' rebuild'
FROM 
    sys.indexes i
JOIN 
    sys.tables t ON i.object_id = t.object_id
WHERE 
    i.type_desc = 'NONCLUSTERED' OR
	i.type_desc = 'CLUSTERED'
    AND i.name IS NOT NULL and i.is_disabled<>0


