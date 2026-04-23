CREATE TABLE [dbo].[tb_oracle_databases](
	[server_monitoring_id] [int] IDENTITY(1,1) NOT NULL,
	[server_name] [varchar](100) NOT NULL,
	[db_Service_name] [varchar](100) NULL,
	[connect_data] [varchar](300) NOT NULL,
	[db_type] [char](1) NOT NULL,
	[active] [char](1) NOT NULL,
	[created_on] [datetime] NOT NULL,
	[notification_age] [int] NULL,
	[last_notification] [datetime] NULL,
	[Monitored] [char](1) NULL,
	[Notes] [varchar](max) NULL
) ON [PRIMARY]
GO
