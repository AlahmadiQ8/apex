-- db/install.sql
-- Master installer. Runs all schema files and migrations in order,
-- recording each in schema_migrations so reruns skip already-applied work.
--
-- This script assumes the calling SQLcl session has WHENEVER SQLERROR EXIT
-- configured (see scripts/deploy.sql).

PROMPT ==> [DB] Running master installer...

PROMPT ==> [DB] 000_schema_migrations
@@schema/000_schema_migrations.sql

PROMPT ==> [DB] 001_create_feedback
@@schema/001_create_feedback.sql
BEGIN
    MERGE INTO schema_migrations t
    USING (SELECT '001_create_feedback' AS version FROM dual) s
    ON (t.version = s.version)
    WHEN NOT MATCHED THEN INSERT (version, notes) VALUES (s.version, 'cf_feedback table');
END;
/

PROMPT ==> [DB] 002_seed_data
@@migrations/002_seed_data.sql
BEGIN
    MERGE INTO schema_migrations t
    USING (SELECT '002_seed_data' AS version FROM dual) s
    ON (t.version = s.version)
    WHEN NOT MATCHED THEN INSERT (version, notes) VALUES (s.version, 'sample feedback rows');
END;
/

PROMPT ==> [DB] 003_add_category
@@migrations/003_add_category.sql
BEGIN
    MERGE INTO schema_migrations t
    USING (SELECT '003_add_category' AS version FROM dual) s
    ON (t.version = s.version)
    WHEN NOT MATCHED THEN INSERT (version, notes) VALUES (s.version, 'category column on cf_feedback');
END;
/

COMMIT;

PROMPT ==> [DB] Applied migrations:
SELECT version, applied_at FROM schema_migrations ORDER BY applied_at;

PROMPT ==> [DB] Master installer complete.
