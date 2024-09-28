
                declare @curr_tracefilename varchar(500); 
                declare @base_tracefilename varchar(500); 
                declare @indx int ;
                declare @temp_trace table (
                        Error int
                ,       StartTime datetime
                ,       NTUserName nvarchar(128)collate database_default 
                ,       NTDomainName nvarchar(128) collate database_default 
                ,       HostName nvarchar(128) collate database_default 
                ,       ApplicationName nvarchar(128) collate database_default 
                ,       LoginName nvarchar(128) collate database_default 
                ,       SPID int
                ,       ServerName nvarchar(128) collate database_default 
                ,       TextData nvarchar (max) collate database_default 
                );
                declare @path_separator CHAR(1) ;
                set @path_separator = ISNULL(CONVERT(CHAR(1), serverproperty('PathSeparator')), '\') ;

                select @curr_tracefilename = path FROM sys.traces where is_default = 1 ; 
                set @curr_tracefilename = reverse(@curr_tracefilename)
                select @indx  = PATINDEX('%'+@path_separator+'%', @curr_tracefilename) 
                set @curr_tracefilename = reverse(@curr_tracefilename)
                set @base_tracefilename = LEFT( @curr_tracefilename,len(@curr_tracefilename) - @indx) + @path_separator + 'log.trc';

                insert into  @temp_trace
                select Error
                ,       StartTime
                ,       NTUserName
                ,       NTDomainName
                ,       HostName
                ,       ApplicationName
                ,       LoginName
                ,       SPID
                ,       ServerName
                ,       TextData
                from ::fn_trace_gettable( @base_tracefilename, default ) 
                where EventClass = 20 --signifies login failed

                select dense_rank () over (order by S.loginname) loginrank
                ,       (dense_rank () over (order by S.loginname))%2 as l_loginrank
                ,       T.Error
                ,       convert(nchar(20), T.StartTime,120) "HitDate"
                ,       T.NTUserName
                ,       T.NTDomainName
                ,       T.HostName
                ,       T.ApplicationName
                ,       T.LoginName
                ,       T.SPID
                ,       T.ServerName
                ,       T.TextData
                ,       case when S.loginname is null then 'InvalidLoginName' else S.loginname end as loginname_1
                ,       case when T.Error in (18462,18463,18464,18465,18466,18467,18468,18471,18487,18488) 
                                 then 4 --'Password Related Problems'
                                 else case when T.Error in (18458,18459,18460) 
                                                   then 2 --'Licensing Related Problems'
                                                        else case when T.Error in (18452,18450,18486,18457) 
                                                                          then 1 --'Authentication Related Problems'
                                                                          else case when T.Error in(18451,18461) 
                                                                                                then 5 --'Server''s Mode of Operation'
                                                    else case when T.Error in (17197) 
                                                                                                                  then 6 --'Slow Server Response'
                                                          else 3 --'Others' 
                                                     end
                                            end
                                                                 end
                                          end
                        end  "Type"
                ,       (dense_rank() over ( order by (case when T.Error in (18462,18463,18464,18465,18466,18467,18468,18471,18487,18488) 
                                                                                                then 4 -- 'Password Related Problems'
                                                                                                else case when T.Error in (18458,18459,18460) 
                                                                                                         then 2 --'Licensing Related Problems'
                                                                                                         else case when T.Error in (18452,18450,18486,18457) 
                                                                                                                  then 1 --'Authentication Related Problems'
                                                                                                                  else case when T.Error in(18451,18461) 
                                                                                                                           then 5 --'Server''s Mode of Operation'
                                                                                                                           else case when T.Error in (17197) 
                                                                                                                                    then 6 --'Slow Server Response'
                                                                                                                                        else 3-- 'Others' 
                                                                                                                                        end
                                                                                                                           end
                                                                                                                  end
                                                                                                         end
                                                                                                end )))%2  as l1
                ,       (row_number() over ( order by (case when T.Error in (18462,18463,18464,18465,18466,18467,18468,18471,18487,18488) 
                                                                                   then 4 --'Password Related Problems'
                                                                                   else case when T.Error in (18458,18459,18460) 
                                                                                                then 2--'Licensing Related Problems'
                                                                                                else case when T.Error in (18452,18450,18486,18457) 
                                                                                                         then 1 --'Authentication Related Problems'
                                                                                                         else case when T.Error in(18451,18461) 
                                                                                                                  then 5 --'Server''s Mode of Operation'
                                                                                                                  else case when T.Error in (17197) 
                                                                                                                           then 6 --'Slow Server Response'
                                                               else 3-- 'Others' 
                                                               end
                                                          end
                                                                                                         end
                                                                                                end
                                                                                   end ),T.StartTime desc))%2  as l2
                from @temp_trace T 
                left outer join sys.syslogins S on(T.LoginName = S.loginname)
