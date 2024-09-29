
create procedure sp_retrieve_sql_agent_Properties
as
/*****************

Author: Collins Robert
Description: Show SQL Agent properties details using T-SQL
Date:  2024/09/29


*****************/
 declare @dirtable table ([value] varchar(max),
[Data] varchar(max) ) ;
declare @profile varchar(max)
insert into @dirtable
exec xp_instance_regread  N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'DatabaseMailProfile'



insert into @dirtable
EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'RestartSQLServer'
insert into @dirtable
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'JobHistoryMaxRows'
                                            
insert into @dirtable
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'JobHistoryMaxRowsPerJob'
insert into @dirtable
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'ErrorLogFile'
insert into @dirtable
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'ErrorLoggingLevel'
insert into @dirtable
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'ErrorMonitor'
insert into @dirtable
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'MonitorAutoStart'
insert into @dirtable
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'ServerHost'
insert into @dirtable
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'JobShutdownTimeout'
insert into @dirtable
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'CmdExecAccount'

insert into @dirtable
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'LoginTimeout'
insert into @dirtable
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'IdleCPUPercent'
insert into @dirtable
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'IdleCPUDuration'
insert into @dirtable
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'OemErrorLog'

insert into @dirtable
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'AlertReplaceRuntimeTokens'  
insert into @dirtable

    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                           N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                           N'CoreEngineMask'

insert into @dirtable
        EXECUTE master.dbo.xp_instance_regdeletevalue N'HKEY_LOCAL_MACHINE',
                                                      N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                                      N'CoreEngineMask'
insert into @dirtable
        EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                                N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                                N'CoreEngineMask'

insert into @dirtable
     EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                            N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                            N'UseDatabaseMail'
	
	select @@SERVERNAME ServerName, * from @dirtable

