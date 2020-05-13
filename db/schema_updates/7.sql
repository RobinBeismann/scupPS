DROP TABLE IF EXISTS [dbo].[users]
GO

CREATE TABLE [dbo].[users](
	[ResourceID] [nchar](150) NOT NULL,
	[SID] [nvarchar](max) NOT NULL,
	[user_created] [datetime] NULL,
	[user_modified] [datetime] NULL,
    CONSTRAINT [PK_users] PRIMARY KEY CLUSTERED 
    (
        [ResourceID] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA] TEXTIMAGE_ON [DATA]
GO

ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_user_created]  DEFAULT (CURRENT_TIMESTAMP) FOR [user_created]
GO

DROP TRIGGER IF EXISTS [dbo].[tr_users_Modified]
GO

CREATE TRIGGER [dbo].[tr_users_Modified]
   ON [dbo].[users]
   AFTER UPDATE
AS BEGIN
    SET NOCOUNT ON;
    BEGIN
        UPDATE [dbo].[users]
        SET user_modified = CURRENT_TIMESTAMP
    END 
END
GO

UPDATE [dbo].[db] SET "db_value"=7 WHERE "db_name" = 'db_version'
GO