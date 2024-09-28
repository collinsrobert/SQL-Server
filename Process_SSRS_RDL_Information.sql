/***
Process SSRS RDL information for easy retrieval


****/

-----Create Tables below
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
