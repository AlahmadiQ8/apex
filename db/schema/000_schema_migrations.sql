-- 000_schema_migrations.sql
-- Tracking table for applied database migrations.
-- Idempotent: catches ORA-00955 (object already exists) on rerun.
--
-- This file is run first by db/install.sql. It enables the rest of the
-- pipeline to skip migrations that have already been applied.

BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE schema_migrations (
            version    VARCHAR2(50) PRIMARY KEY,
            applied_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
            applied_by VARCHAR2(100) DEFAULT USER NOT NULL,
            notes      VARCHAR2(4000)
        )
    ]';
    DBMS_OUTPUT.PUT_LINE('Created schema_migrations table.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE('schema_migrations table already exists -- skipping.');
        ELSE
            RAISE;
        END IF;
END;
/
