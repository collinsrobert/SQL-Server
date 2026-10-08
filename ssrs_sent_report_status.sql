

/****** Object:  View [dbo].[vw_failed_sent_report_status]    Script Date: 10/8/2026 9:10:11 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[vw_failed_sent_report_status]

as

SELECT 
	--Subscriptions
	distinct rs.[ScheduleID] "SQL Agent Job Name"      
	,rc.Name ReportName
	,rc.Path
    ,s.Description AS SubscriptionDescription
	,sch.Name AS SharedScheduleName
	
	--Dates
	,s.LastRunTime as LastRunTimeFull,
	YEAR(s.LastRunTime) as LastRunYear,
	RIGHT('0' + RTRIM(MONTH(s.LastRunTime)),2) as LastRunMonth,
	DATEPART(QUARTER,s.LastRunTime) as LastRunQuarter,
	CONVERT(VARCHAR(5),s.LastRunTime,108) as LastRunTime,
	CASE WHEN DATEPART(HOUR,s.LastRunTime) > 11 THEN 'PM' ELSE 'AM' END as LastRunAmPm,
	--Used '#: FROM-TO' format to sort/rank correctly
	CASE 
		WHEN CONVERT(VARCHAR(5),s.LastRunTime,108) BETWEEN '24:00' AND '04:00' THEN '1: 12AM-4AM'
		WHEN CONVERT(VARCHAR(5),s.LastRunTime,108) BETWEEN '04:00' AND '08:00' THEN '2: 4AM-8AM'
		WHEN CONVERT(VARCHAR(5),s.LastRunTime,108) BETWEEN '08:00' AND '12:00' THEN '3: 8AM-12PM'
		WHEN CONVERT(VARCHAR(5),s.LastRunTime,108) BETWEEN '12:00' AND '16:00' THEN '4: 12PM-4PM'
		WHEN CONVERT(VARCHAR(5),s.LastRunTime,108) BETWEEN '16:00' AND '20:00' THEN '5: 4PM-8PM'
		ELSE '6: 8PM-12AM'
		END AS LastRunTimeRange

	--Statuses
	,s.LastStatus
	,CASE WHEN s.LastStatus LIKE '%Fail%' THEN 1 ELSE NULL END AS CountFailedStatus
	,CASE WHEN s.LastStatus LIKE '%Pending%' THEN 1 ELSE NULL END AS CountPendingStatus,
	1 AS CountEachStatus
FROM 
	[ReportServer].[dbo].[ReportSchedule] rs
	JOIN [ReportServer].[dbo].[Subscriptions] s ON rs.ReportID=s.Report_OID
	JOIN [ReportServer].[dbo].[Schedule] sch ON sch.ScheduleID=rs.ScheduleID
	JOIN [ReportServer].[dbo].[Catalog] rc ON rc.ItemID=rs.ReportID
WHERE s.laststatus not like '%Mail sent%' and
	s.laststatus not like '%Disabled%' and
	s.laststatus not like '%Done%' and
	s.laststatus not like '%Caching for the item%' and
	s.laststatus not like '%The subscription contains parameter values that are not valid.%'
  
GO


