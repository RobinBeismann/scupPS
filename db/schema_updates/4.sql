DROP TABLE IF EXISTS [dbo].[costcenters]
GO

CREATE TABLE [dbo].[costcenters](
	[costcenter_id] [nchar](150) NOT NULL,
	[costcenter_managers] [nvarchar](max) NOT NULL,
	[costcenter_created] [datetime] NULL,
	[costcenter_modified] [datetime] NULL,
    )
GO

ALTER TABLE [dbo].[costcenters] ADD  CONSTRAINT [DF_costcenters_costcenter_created]  DEFAULT (CURRENT_TIMESTAMP) FOR [costcenter_created]
GO

DROP TRIGGER IF EXISTS [dbo].[tr_costcenters_Modified]
GO

CREATE TRIGGER [dbo].[tr_costcenters_Modified]
   ON [dbo].[costcenters]
   AFTER UPDATE
AS BEGIN
    SET NOCOUNT ON;
    BEGIN
        UPDATE [dbo].[costcenters]
        SET costcenter_modified = CURRENT_TIMESTAMP
    END 
END

GO

UPDATE [dbo].[db] SET "db_value"=4 WHERE "db_name" = 'db_version';