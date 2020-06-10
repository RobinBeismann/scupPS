
ALTER TABLE "costcenterManagers"
    DROP CONSTRAINT "PK_costcenterManagers";
GO

ALTER TABLE "costcenterManagers"
    DROP COLUMN "relation_id";
GO

UPDATE [dbo].[db] SET "db_value"=13 WHERE "db_name" = 'db_version'
GO