use ODS
go
EXEC sp_changepublication
@publication ='Publication_Name',
@property='immediate_sync',
@value='false'
go

EXEC sp_changepublication
@publication ='Publication_Name',
@property='allow_anonymous',
@value='false'
go

select @@SERVERNAME

--make changes
---run snapshot



use ODS
go
EXEC sp_changepublication
@publication ='Publication_Name',
@property='immediate_sync',
@value='true'
go

EXEC sp_changepublication
@publication ='Publication_Name',
@property='allow_anonymous',
@value='true'
go
