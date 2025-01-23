
ALso get change tracking
Permissoins
Indexes scripted out.


Run the following on the publication server


select @@SERVERNAME  ----returns the servername

use Database_Name
go

EXEC sp_changepublication
@publication ='Publication_Name',---Add the publication Name
@property='allow_anonymous',
@value='false'
go

EXEC sp_changepublication
@publication ='Publication_Name',  ---Add the publication Name
@property='immediate_sync',
@value='false'
go

--If there is an error above, re-run the queries above

--make changes
This involves either adding a new article to the publication or removing, modifying and adding back an exisiting article to the publication.
Remove the article from the publication
Modify the article outside the publication
Add the article to the publication


---run snapshot

-- Execute the scripts below.
use Database_Name
go
EXEC sp_changepublication
@publication ='Publication_Name',---Add the publication Name
@property='allow_anonymous',
@value='true'
go

EXEC sp_changepublication
@publication ='Publication_Name',---Add the publication Name
@property='immediate_sync',
@value='true'
go


--If there is an error above, re-run the queries above
