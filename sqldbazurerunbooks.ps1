Write-Output "Run started"

try {

    # Instantiate the connection to the SQL Database

    $sqlConnection = new-object System.Data.SqlClient.SqlConnection

    $sqlConnection.ConnectionString = "Data Source=connectionstring.database.windows.net;Initial Catalog=edwtest;Integrated Security=False;User ID=dba_user;Password=<password>;Connect Timeout=60;Encrypt=False;TrustServerCertificate=False"

    $sqlConnection.Open()

    Write-Output "Azure SQL database connection opened"

 
     # Define the SQL command to run

    $sqlCommand = new-object System.Data.SqlClient.SqlCommand

    $sqlCommand.CommandTimeout = 12000 #change this & connection timeout when implementing in Prod

    $sqlCommand.Connection = $sqlConnection

    Write-Output "Issuing command to run stored procedure"

 

    # Execute the SQL command

    $sqlCommand.CommandText= 

    "exec  [dbo].[IndexOptimize] 
@Databases = 'edwtest',
@FragmentationLow = NULL,
@FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationLevel1 = 50,
@FragmentationLevel2 = 80,
@UpdateStatistics = 'ALL',
@OnlyModifiedStatistics = 'Y',
@SortInTempdb = 'Y'"

    $result = $sqlCommand.ExecuteNonQuery()

    Write-Output "Stored procedure execution completed"

}

catch {

    Write-Output "An error occurred: $_"

    # Handle the error here, you can log it, send an email, etc.

    # The script will fail at this point due to the error.

    $errorOccurred = $true

    Throw $_  # This will generate a terminating error and set the job status to "Failed"

}

finally {

    # Close the SQL connection in the 'finally' block to ensure it is closed even in case of an error.

    if ($sqlConnection.State -eq 'Open') {

        $sqlConnection.Close()

        Write-Output "SQL connection closed"

    }

}

if ($errorOccurred) {

    Write-Output "Run completed with errors"

}

else {

    Write-Output "Run completed successfully"

	}
