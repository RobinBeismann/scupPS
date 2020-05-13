DROP TABLE IF EXISTS [dbo].[applications]
GO

CREATE TABLE [dbo].[applications](
	[app_modelname] [nchar](150) NOT NULL,
	[app_publisher] [nvarchar](max) NOT NULL,
	[app_title] [nvarchar](max) NOT NULL,
	[app_description] [nvarchar](max) NOT NULL,
	[app_created] [datetime] NULL,
	[app_modified] [datetime] NULL,
    CONSTRAINT [PK_applications] PRIMARY KEY CLUSTERED 
    (
        [app_modelname] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA] TEXTIMAGE_ON [DATA]
GO

ALTER TABLE [dbo].[applications] ADD  CONSTRAINT [DF_applications_app_created]  DEFAULT (CURRENT_TIMESTAMP) FOR [app_created]
GO

DROP TRIGGER IF EXISTS [dbo].[tr_applications_Modified]
GO

CREATE TRIGGER [dbo].[tr_applications_Modified]
   ON [dbo].[applications]
   AFTER UPDATE
AS BEGIN
    SET NOCOUNT ON;
    BEGIN
        UPDATE [dbo].[applications]
        SET app_modified = CURRENT_TIMESTAMP
    END 
END

GO

UPDATE [dbo].[db] SET "db_value"=3 WHERE "db_name" = 'db_version';