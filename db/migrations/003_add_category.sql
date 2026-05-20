-- 003_add_category.sql
-- THE DEMO MOMENT: adds a category column to cf_feedback.
-- Idempotent: catches ORA-01430 (column already exists).
--
-- This migration is the change demonstrated on stage:
--   1. A stakeholder opens an issue requesting a "category" field.
--   2. A developer adds this migration + the matching APEX page change.
--   3. The PR triggers validation; merge deploys to DEV.
--   4. Tagging a release deploys to PROD after manual approval.

BEGIN
    EXECUTE IMMEDIATE q'[
        ALTER TABLE cf_feedback
            ADD category VARCHAR2(50) DEFAULT 'General'
                CONSTRAINT cf_feedback_cat_chk
                CHECK (category IN ('General','Product','Support','Billing','Other'))
    ]';
    DBMS_OUTPUT.PUT_LINE('Added category column to cf_feedback.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1430 THEN
            DBMS_OUTPUT.PUT_LINE('cf_feedback.category already exists -- skipping.');
        ELSE
            RAISE;
        END IF;
END;
/

COMMENT ON COLUMN cf_feedback.category IS 'Feedback category, added in v1.1';
