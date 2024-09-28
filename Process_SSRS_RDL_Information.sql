/***

Author: Collins Robert
Date:
Process SSRS RDL information for easy retrieval
This will provide the following information about SSRS reports
You need to ensure this is being processed from the database server hosting the reports.
This assusmes that the database name is ReportServer

****/

-----####################################################Create Tables below
-----#####################rdl_info_processed
-----#####################
USE [Master]
GO

/****** Object:  Table [dbo].[rdl_info_processed]    Script Date: 9/28/2024 6:33:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[rdl_info_processed](
	[name] [nvarchar](425) NOT NULL,
	[Path] [varchar](200) NOT NULL,
	[Report Description] [varchar](500) NULL,
	[DataSourceName] [varchar](max) NULL,
	[CommandType] [varchar](20) NULL,
	[CommandText] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO




USE [IMG_DataServices]
GO

/****** Object:  Table [dbo].[rdl_info_master]    Script Date: 9/28/2024 6:39:02 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[rdl_info_master](
	[Name] [nvarchar](425) NOT NULL,
	[Type] [int] NOT NULL,
	[Path] [varchar](200) NOT NULL,
	[TypeDescription] [varchar](14) NOT NULL,
	[Report Description] [varchar](500) NULL,
	[ContentXML] [xml] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
