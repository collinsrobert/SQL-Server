

-----------###################################Table


USE [Master]
GO

/****** Object:  Table [dbo].[subscriptions]    Script Date: 9/29/2024 1:16:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[subscriptions](
	[SubscriptionID] [uniqueidentifier] NOT NULL,
	[OwnerID] [uniqueidentifier] NOT NULL,
	[Report_OID] [uniqueidentifier] NOT NULL,
	[Locale] [nvarchar](128) NOT NULL,
	[InactiveFlags] [int] NOT NULL,
	[ExtensionSettings] [ntext] NULL,
	[ModifiedByID] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[Description] [nvarchar](512) NULL,
	[LastStatus] [nvarchar](260) NULL,
	[EventType] [nvarchar](260) NOT NULL,
	[MatchData] [ntext] NULL,
	[LastRunTime] [datetime] NULL,
	[Parameters] [ntext] NULL,
	[DataSettings] [ntext] NULL,
	[DeliveryExtension] [nvarchar](260) NULL,
	[Version] [int] NOT NULL,
	[ReportZone] [int] NOT NULL,
	[Updated_On] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

















-------##########################################Procedure
USE [Master]
GO

/****** Object:  StoredProcedure [dbo].[usp_report_subscription_monitor]    Script Date: 9/29/2024 1:07:45 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[usp_report_subscription_monitor]
as
/*
*Author: Collins Robert
*Date:4/03/2019
*Date modified:7/19/2023     BY: Collins Robert
*Date modified:      BY:  
*Description:################################################################################
                      #This procedure monitors report subscription owner.####################
                      #It alerts data Services when the owner is not svc_ACCOUNT#########
                      ####################################################################### 
*/
declare
@report_name varchar(70),
@subsc_owner varchar(30),
@sched_name varchar(100),
@report_path varchar(300),
@modified_date datetime,
@message varchar(max),
@profile varchar(max),
@subdisc varchar(300),
@counter tinyint;


set @message = '<style type="text/css">
    #Header{font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;width:100%;border-collapse:collapse;}
    #Header td, #Header th {font-size:14px;border:1px solid #a00000;padding:3px 7px 2px 7px;}
    #Header th {font-size:14px;text-align:left;padding-top:5px;padding-bottom:4px;background-color:#02144c;color:#fff;}
    #Header tr.alt td {color:#000;background-color:#EAF2D3;}
    </Style>';
set @message+= '<HTML><BODY><Table border=1 cellpadding=0 cellspacing=0 width=100% id=Header>
        <TR>
            <TH><B>Report Name</B></TH>
            <TH><B>Subscription Owner</B></TD>
                          <TH><B>Report Path</B></TH>
						  <TH><B>Subscription Discription<B></TH>
                    
                                  
        </TR>'
declare report_notification_cur CURSOR FOR
SELECT 
CAT.Name as ReportName
,USR.UserName AS SubscriptionOwner 
,SCH.Name AS ScheduleName 
,CAT.[Path] AS ReportPath
,SUB.[Description] AS SubscriptionDescription 
,SUB.ModifiedDate 

FROM ReportServer.dbo.Subscriptions AS SUB 
INNER JOIN ReportServer.dbo.Users AS USR 
ON SUB.OwnerID = USR.UserID 
INNER JOIN ReportServer.dbo.[Catalog] AS CAT 
ON SUB.Report_OID = CAT.ItemID 
INNER JOIN ReportServer.dbo.ReportSchedule AS RS 
ON SUB.Report_OID = RS.ReportID 
AND SUB.SubscriptionID = RS.SubscriptionID 
INNER JOIN ReportServer.dbo.Schedule AS SCH 
ON RS.ScheduleID = SCH.ScheduleID 
where USR.UserName<>'EXAMPLE\SVC.ACCOUNT'

OPEN report_notification_cur
fetch next from report_notification_cur
INTO  @report_name, @subsc_owner , @sched_name , @report_path ,@subdisc,  @modified_date
while @@FETCH_STATUS = 0
 Begin
 --set @message+= '<TR bgColor=''#ba1d1d''><TD colspan=8 align=left><B>$ServerName</B></TD></TR>';
 if   @subsc_owner<>'EXAMPLE\SVC.ACCOUNT'
 Begin
 set @counter=1;
 set @message+='<TR>
                    <TD>'+@report_name+'</TD>
                    <TD>'+@subsc_owner+'</TD>
                                  <TD> '+@report_path+'</TD>
								  <TD> '+@subdisc+'</TD>
                                  
                                                                                  
               </TR>'
End
        --Debug      
       --select  @report_name, @subsc_owner , @sched_name , @report_path , @modified_date
       fetch next from report_notification_cur
INTO  @report_name, @subsc_owner , @sched_name , @report_path ,@subdisc, @modified_date
END
Close report_notification_cur;
Deallocate report_notification_cur;
if @counter=1
begin
---get the email profile
 select @profile= max(name)
from msdb.dbo.sysmail_profile 
---Send notification email 
EXEC msdb.dbo.sp_send_dbmail
@profile_name = @profile,
                     @recipients = 'email@example.com',
                     @body_format = 'HTML',
                     @body =  @message,
              @subject = 'Report Subcription Owner Alert and Update' ;

--save off before update

insert into Master.dbo.subscriptions([SubscriptionID]
      ,[OwnerID]
      ,[Report_OID]
      ,[Locale]
      ,[InactiveFlags]
      ,[ExtensionSettings]
      ,[ModifiedByID]
      ,[ModifiedDate]
      ,[Description]
      ,[LastStatus]
      ,[EventType]
      ,[MatchData]
      ,[LastRunTime]
      ,[Parameters]
      ,[DataSettings]
      ,[DeliveryExtension]
      ,[Version]
      ,[ReportZone]
	  ,Updated_On)select [SubscriptionID]
      ,[OwnerID]
      ,[Report_OID]
      ,[Locale]
      ,[InactiveFlags]
      ,[ExtensionSettings]
      ,[ModifiedByID]
      ,[ModifiedDate]
      ,[Description]
      ,[LastStatus]
      ,[EventType]
      ,[MatchData]
      ,[LastRunTime]
      ,[Parameters]
      ,[DataSettings]
      ,[DeliveryExtension]
      ,[Version]
      ,[ReportZone]
	  ,getdate() as Updated_On 
	  from [ReportServer].[dbo].[Subscriptions]
	  where OwnerID <>'77F68630-30D0-4A06-AD44-8FD17CD421F6';

--automate subscription update
update  [ReportServer].[dbo].[Subscriptions]
set OwnerID='77F68630-30D0-4A06-AD44-8FD17CD421F6'
where OwnerID <>'77F68630-30D0-4A06-AD44-8FD17CD421F6'

end



GO



--------------#######################SQL Agent Job





