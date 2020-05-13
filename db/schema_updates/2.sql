DROP TABLE IF EXISTS [dbo].[config]
GO

CREATE TABLE [dbo].[config](
	[config_name] [nchar](150) NOT NULL,
	[config_value] [nvarchar](max) NULL,
	[config_created] [datetime] NULL,
	[config_modified] [datetime] NULL,
    CONSTRAINT [PK_config] PRIMARY KEY CLUSTERED 
    (
        [config_name] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA] TEXTIMAGE_ON [DATA]
GO

ALTER TABLE [dbo].[config] ADD  CONSTRAINT [DF_config_config_created]  DEFAULT (CURRENT_TIMESTAMP) FOR [config_created]
GO

DROP TRIGGER IF EXISTS [dbo].[tr_config_Modified]
GO

CREATE TRIGGER [dbo].[tr_config_Modified]
   ON [dbo].[config]
   AFTER UPDATE
AS BEGIN
    SET NOCOUNT ON;
    BEGIN
        UPDATE [dbo].[config]
        SET config_modified = CURRENT_TIMESTAMP
    END 
END

GO

UPDATE [dbo].[db] SET "db_value"=2 WHERE "db_name" = 'db_version';