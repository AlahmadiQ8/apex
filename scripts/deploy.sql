-- scripts/deploy.sql
-- SQLcl master orchestrator -- called from the deploy workflow.
--
-- WHENEVER SQLERROR EXIT is critical for CI: without it, SQLcl silently
-- continues on SQL errors and exits 0 (false-green pipeline).

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
WHENEVER OSERROR  EXIT 9 ROLLBACK
SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF

PROMPT ============================================================
PROMPT  APEX CI/CD demo -- deploy.sql
PROMPT ============================================================

PROMPT ==> [1/1] Applying database schema and migrations...
@@../db/install.sql

PROMPT ============================================================
PROMPT  deploy.sql complete.
PROMPT ============================================================

EXIT 0
