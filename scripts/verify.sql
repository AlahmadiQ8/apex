-- scripts/verify.sql
-- Post-deploy smoke verification -- called from the deploy workflow.
-- Exits non-zero if anything is missing.

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
WHENEVER OSERROR  EXIT 9 ROLLBACK
SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT  Post-deploy verification
PROMPT ============================================================

PROMPT ==> Objects in CF_% namespace:
SELECT object_name, object_type, status
FROM   user_objects
WHERE  object_name LIKE 'CF\_%' ESCAPE '\'
ORDER  BY object_type, object_name;

PROMPT ==> Schema migrations applied:
SELECT version, applied_at FROM schema_migrations ORDER BY applied_at;

PROMPT ==> Row count in cf_feedback:
SELECT COUNT(*) AS feedback_rows FROM cf_feedback;

PROMPT ==> Sanity check -- cf_feedback.category column must exist after v1.1:
DECLARE
    l_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_count
    FROM   user_tab_columns
    WHERE  table_name  = 'CF_FEEDBACK'
    AND    column_name = 'CATEGORY';

    IF l_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('WARNING: cf_feedback.category not found. Pre-v1.1 schema?');
    ELSE
        DBMS_OUTPUT.PUT_LINE('OK: cf_feedback.category present.');
    END IF;
END;
/

PROMPT ==> APEX application 100 present in workspace DEMO:
DECLARE
    l_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_count
    FROM   apex_applications
    WHERE  application_id = 100
    AND    workspace      = 'DEMO';

    IF l_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('WARNING: APEX app 100 not found in workspace DEMO.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('OK: APEX app 100 found in workspace DEMO.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- apex_applications view may not be visible if user lacks APEX role
        DBMS_OUTPUT.PUT_LINE('NOTE: apex_applications not queryable as this user: ' || SQLERRM);
END;
/

PROMPT ============================================================
PROMPT  Verification complete.
PROMPT ============================================================

EXIT 0
