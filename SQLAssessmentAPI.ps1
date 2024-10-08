get-SqlInstance -ServerInstance 'Servernametobeassessed' | Invoke-Sqlassessment -FlattenOutput | Write-SqlTableData -ServerInstance 'TargetServerToStoreAssessmentResults' -DatabaseName TargetDatabaseNameToHoldResults -SchemaName Assessment -TableName Assessment_Results -Force 

