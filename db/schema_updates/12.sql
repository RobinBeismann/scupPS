ALTER TABLE "costcenters"
DROP COLUMN "costcenter_managers";
GO

UPDATE [dbo].[db] SET "db_value"=12 WHERE "db_name" = 'db_version'
GO