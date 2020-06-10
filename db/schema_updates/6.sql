ALTER TABLE applications ALTER COLUMN app_publisher [nvarchar](max) NULL;

UPDATE [dbo].[db] SET "db_value"=6 WHERE "db_name" = 'db_version';