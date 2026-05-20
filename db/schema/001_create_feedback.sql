-- 001_create_feedback.sql
-- Customer Feedback table -- the single domain object for the demo app.
-- Idempotent: catches ORA-00955 (table exists) and ORA-00955/-01408 (index exists).

BEGIN
    EXECUTE IMMEDIATE q'[
        CREATE TABLE cf_feedback (
            id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            name       VARCHAR2(100) NOT NULL,
            email      VARCHAR2(150),
            rating     NUMBER(1) NOT NULL CHECK (rating BETWEEN 1 AND 5),
            comments   VARCHAR2(4000),
            created_at DATE DEFAULT SYSDATE NOT NULL
        )
    ]';
    DBMS_OUTPUT.PUT_LINE('Created cf_feedback table.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE('cf_feedback table already exists -- skipping.');
        ELSE
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX cf_feedback_rating_idx  ON cf_feedback (rating)';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-955, -1408) THEN NULL; ELSE RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX cf_feedback_created_idx ON cf_feedback (created_at)';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE IN (-955, -1408) THEN NULL; ELSE RAISE; END IF;
END;
/
