ALTER TABLE [dbo].[users]
ALTER COLUMN SID [nchar](150) NULL;
GO

IF (OBJECT_ID('dbo.conUserSid', 'UQ') IS NOT NULL)
BEGIN
	ALTER TABLE [dbo].[users]
	DROP CONSTRAINT conUserSid
END
GO

ALTER TABLE [dbo].[users]
ADD CONSTRAINT conUserSid unique(SID);
GO

ALTER TABLE [dbo].[ApplicationRequests]
ALTER COLUMN UserSid [nchar](150) NULL;
GO

ALTER TABLE [dbo].[ApplicationRequests]
ADD FOREIGN KEY (UserSid) REFERENCES users(SID);
GO

UPDATE [dbo].[db] SET "db_value"=10 WHERE "db_name" = 'db_version'
GO