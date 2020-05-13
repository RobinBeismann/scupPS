ALTER TABLE applications ALTER COLUMN app_description [nvarchar](max) NULL;

UPDATE [dbo].[db] SET "db_value"=5 WHERE "db_name" = 'db_version';