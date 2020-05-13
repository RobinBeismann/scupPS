DROP TABLE IF EXISTS [dbo].[ApplicationRequests]

CREATE TABLE [dbo].[ApplicationRequests](
	[RequestGuid] [nchar](150) NOT NULL,
	[ModelName] [nvarchar](max) NOT NULL,
	[RequestedMachine] [nchar](150) NOT NULL,
	[RequestHistory] [nvarchar](max) NOT NULL,
	[User] [nvarchar](max) NOT NULL,
	[UserSid] [nvarchar](max) NOT NULL,
	[CurrentState] [nvarchar](max) NOT NULL,
	[Comments] [nvarchar](max) NOT NULL,
	[CI_UniqueID] [nvarchar](max) NOT NULL,
	[Application] [nvarchar](max) NOT NULL,
	[request_created] [datetime] NULL,
	[request_modified] [datetime] NULL,
    CONSTRAINT [PK_ApplicationRequests] PRIMARY KEY CLUSTERED 
    (
        [RequestGuid] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DATA]
) ON [DATA] TEXTIMAGE_ON [DATA]
GO

ALTER TABLE [dbo].[ApplicationRequests] ADD  CONSTRAINT [DF_ApplicationRequests_request_created]  DEFAULT (CURRENT_TIMESTAMP) FOR [request_created]
GO

DROP TRIGGER IF EXISTS [dbo].[tr_ApplicationRequests_Modified]
GO

CREATE TRIGGER [dbo].[tr_ApplicationRequests_Modified]
   ON [dbo].[ApplicationRequests]
   AFTER UPDATE
AS BEGIN
    SET NOCOUNT ON;
    BEGIN
        UPDATE [dbo].[ApplicationRequests]
        SET request_modified = CURRENT_TIMESTAMP
    END 
END
GO

UPDATE [dbo].[db] SET "db_value"=8 WHERE "db_name" = 'db_version'
