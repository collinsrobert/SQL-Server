Import-Module “sqlps” -DisableNameChecking
$ServerName = Invoke-Sqlcmd -Query "select server_name from vw_server_listing" -ServerInstance "sqlpv0042" -Database "db_util"
$databaseName = "db_util"
$ConvertToGB = (1024 * 1024 * 1024)
$date = get-date -Format "yyyy-MM-dd HH:mm:ss"
    $conn = New-Object System.Data.SQLClient.SQLConnection
    $ConnectionString ="sqlpv0042;Database=$databaseName;trusted_connection=true;"
    $conn.ConnectionString=$ConnectionString 
    $conn.Open()
foreach ($Server in $ServerName) 
        {
        $wmiObject = Get-WmiObject Win32_Volume -ComputerName $Server.server_name  | Where-Object { $_.DriveLetter -ge 'C:' } | Where-Object { $_.DriveType -eq 3 }
        Foreach ($logicalDisk in $wmiObject)
        {
    $commandText = "INSERT All_DB_Server_Drive_Space VALUES ('"+$logicalDisk.SystemName +"','"+$logicalDisk.DriveLetter+"','"+$logicalDisk.Capacity+"','"+($logicalDisk.Capacity/$ConvertToGB)+"','"+$logicalDisk.FreeSpace+"','"+($logicalDisk.FreeSpace/$ConvertToGB)+"','"+$date+"','"+(($logicalDisk.FreeSpace/$logicalDisk.Capacity)*100 -as [int])+"')" 
    $command = $conn.CreateCommand()
    $command.CommandText = $commandText
    $command.ExecuteNonQuery()
    Write-Output $commandText
    }

} #foreach
$conn.Close()
