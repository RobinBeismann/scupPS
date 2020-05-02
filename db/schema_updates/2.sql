CREATE TABLE "main"."config" (
	"config_name"  TEXT,
	"config_value"  TEXT,
	"config_created"  NOT NULL DEFAULT CURRENT_TIMESTAMP,
	"config_modified"  TEXT,
	PRIMARY KEY ("config_name")
)
;

--Create before update and after insert triggers:
CREATE TRIGGER UPDATE_config BEFORE UPDATE ON config
    BEGIN
       UPDATE config SET config_modified = datetime('now', 'localtime')
       WHERE rowid = new.rowid;
    END
;
CREATE TRIGGER INSERT_config AFTER INSERT ON config
    BEGIN
       UPDATE config SET config_modified = datetime('now', 'localtime')
       WHERE rowid = new.rowid;
    END
;

UPDATE "main"."db" SET "db_version"=2 WHERE _ROWID_ = 1;