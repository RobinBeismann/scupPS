CREATE TABLE "main"."applications" (
    "app_modelname"  TEXT,
    "app_publisher"  TEXT,
    "app_title"  TEXT,
    "app_description"  TEXT,
	"app_created"  NOT NULL DEFAULT CURRENT_TIMESTAMP,
	"app_modified"  TEXT,
	PRIMARY KEY ("app_modelname")
)
;

--Create before update and after insert triggers:
CREATE TRIGGER UPDATE_applications BEFORE UPDATE ON applications
    BEGIN
       UPDATE applications SET app_modified = datetime('now', 'localtime')
       WHERE rowid = new.rowid;
    END
;
CREATE TRIGGER INSERT_applications AFTER INSERT ON applications
    BEGIN
       UPDATE applications SET app_modified = datetime('now', 'localtime')
       WHERE rowid = new.rowid;
    END
;

UPDATE "main"."db" SET "db_version"=3 WHERE _ROWID_ = 1;