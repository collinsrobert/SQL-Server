
create view [dbo].[vw_report_sent_status]
as
/*
Author: Collins Robert
Date: 08/16/2018
Purpose: Use this view to check LastSent Status of all reports scheduled in report server

*/

SELECT distinct rs.[ScheduleID] "SQL Agent Job Name"
      --,rs.[ReportID]
	  ,rc.Name Report_name
	  ,rc.Path
     -- ,rs.[SubscriptionID]
     ,s.LastStatus
	 ,s.LastRunTime
	 ,s.Description
	 ,sch.Name
  FROM [ReportServer].[dbo].[ReportSchedule] rs
  join [ReportServer].[dbo].[Subscriptions] s on rs.ReportID=s.Report_OID
  join [ReportServer].[dbo].[Schedule] sch on sch.ScheduleID=rs.ScheduleID
  join  [ReportServer].[dbo].[Catalog] rc on rc.ItemID=rs.ReportID-- where rc.Name like '%Pick%'
GO
