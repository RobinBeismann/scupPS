CREATE TABLE "main"."nav" (
	"nav_name"  TEXT,
	"nav_baseName"  TEXT,
	"nav_role"  TEXT,
	"nav_url"  TEXT,
	"nav_created"	NOT NULL DEFAULT CURRENT_TIMESTAMP,
	"nav_modified"  TEXT,
	PRIMARY KEY ("nav_name")
)
;

--Create before update and after insert triggers:
CREATE TRIGGER UPDATE_nav BEFORE UPDATE ON nav
    BEGIN
       UPDATE nav SET nav_modified = datetime('now', 'localtime')
       WHERE rowid = new.rowid;
    END
;
CREATE TRIGGER INSERT_nav AFTER INSERT ON nav
    BEGIN
       UPDATE nav SET nav_modified = datetime('now', 'localtime')
       WHERE rowid = new.rowid;
    END
;

UPDATE "main"."db" SET "db_version"=4 WHERE _ROWID_ = 1