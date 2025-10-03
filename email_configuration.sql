-------------------------------------------------------------
--  Database Mail Simple Configuration Template.
--
--  This template creates a Database Mail profile, an SMTP account and 
--  associates the account to the profile.
--  The template does not grant access to the new profile for
--  any database principals.  Use msdb.dbo.sysmail_add_principalprofile
--  to grant access to the new profile for users who are not
--  members of sysadmin.
--#
--#
--  Author:  Collins Robert
--  Date: 2020/01/21
-------------------------------------------------------------

--Enable Database Mail Feature 

sp_configure 'show advanced options', 1;  
GO  
RECONFIGURE;  
GO  
sp_configure 'Database Mail XPs', 1;  
GO  
RECONFIGURE  
GO

--Creeate database mail

DECLARE @profile_name sysname,
        @account_name sysname,
        @SMTP_servername sysname,
        @email_address NVARCHAR(128),
		@replyto_email_address NVARCHAR(128),
		@port tinyint,
		@err_msg NVARCHAR(398),
	    @display_name NVARCHAR(128);

-- Profile name. Replace with the name for your profile
        SET @profile_name = 'Default SQL Server Database Mail Profile';

-- Account information. Replace with the information for your account.
		
		SET @account_name = @@servername;
		SET @SMTP_servername = smtp.gmail.com';
		SET @email_address = replace(@@SERVERNAME,'\','_')+'@liusight.com';
		SET @replyto_email_address=replace(@@SERVERNAME,'\','_')+'_do.not.reply@liusight.com';
        SET @display_name = replace(@@SERVERNAME,'\','_');


-- Verify the specified account and profile do not already exist.
IF EXISTS (SELECT * FROM msdb.dbo.sysmail_profile WHERE name = @profile_name)
BEGIN
  RAISERROR('The specified Database Mail profile (Default SQL Server Database Mail Profile) already exists.', 16, 1);
  GOTO done;
END;

IF EXISTS (SELECT * FROM msdb.dbo.sysmail_account WHERE name = @account_name )
BEGIN
SET @err_msg='The specified Database Mail account ('+@@servername+') already exists.';
 RAISERROR(@err_msg, 16, 1) ;
 GOTO done;
END;

-- Start a transaction before adding the account and the profile
BEGIN TRANSACTION ;

DECLARE @rv INT;

-- Add the account
EXECUTE @rv=msdb.dbo.sysmail_add_account_sp
    @account_name = @account_name,
    @email_address = @email_address,
    @display_name = @display_name,
	@replyto_address=@replyto_email_address,
	@port=25,
    @mailserver_name = @SMTP_servername;

IF @rv<>0
BEGIN
SET @err_msg='Failed to create the specified Database Mail account ('+@@servername+').';
    RAISERROR(@err_msg, 16, 1) ;
    GOTO done;
END

-- Add the profile
EXECUTE @rv=msdb.dbo.sysmail_add_profile_sp
    @profile_name = @profile_name ;

IF @rv<>0
BEGIN
    RAISERROR('Failed to create the specified Database Mail profile (Default SQL Server Database Mail Profile).', 16, 1);
	ROLLBACK TRANSACTION;
    GOTO done;
END;

-- Associate the account with the profile.
EXECUTE @rv=msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = @profile_name,
    @account_name = @account_name,
    @sequence_number = 1 ;

IF @rv<>0
BEGIN
SET @err_msg='Failed to associate the specified profile with the specified account ('+@@servername+').';
    RAISERROR(@err_msg, 16, 1) ;
	ROLLBACK TRANSACTION;
    GOTO done;
END;

COMMIT TRANSACTION;

done:

GO

USE [msdb]
GO
CREATE USER [dbamon] FOR LOGIN [dbamon]
GO
USE [msdb]
GO
ALTER ROLE [db_datareader] ADD MEMBER [dbamon]
GO

grant execute to dbamon
go

EXECUTE msdb.dbo.sysmail_add_principalprofile_sp

 @principal_name = 'public',

 @profile_name = 'Default SQL Server Database Mail Profile',

 @is_default = 1 ;
