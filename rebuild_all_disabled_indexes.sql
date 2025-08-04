SELECT 
    t.name AS TableName,
	schema_name(t.schema_id) schemaname,
    i.name AS IndexName,
	i.is_disabled,
	i.type_desc,
	'alter index ['+i.name+'] ON '+schema_name(t.schema_id)+'.'+t.name +' rebuild'
FROM 
    sys.indexes i
JOIN 
    sys.tables t ON i.object_id = t.object_id
WHERE 
    i.type_desc in( 'NONCLUSTERED','CLUSTERED')
    AND i.name IS NOT NULL and i.is_disabled<>0


