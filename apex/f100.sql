-- f100.sql
-- ===========================================================================
-- APEX application export -- Customer Feedback demo app (id 100, workspace DEMO)
--
-- *** SYNTHETIC PLACEHOLDER ***
-- This file is a MINIMAL hand-crafted APEX import. It is intentionally small
-- and exists so the surrounding CI/CD pipeline (secrets, environments,
-- releases, gates) can be demonstrated end-to-end before a customer has
-- built the real app in their workspace.
--
-- For a real customer demo, replace this file with a real export:
--   SQL> apex export -applicationid 100
-- See apex/README.md for the full procedure.
-- ===========================================================================
--
-- Targets APEX 24.2 import API (wwv_flow_imp). For older versions you may
-- need to adjust the package or call signatures.

set define off
set verify off
set feedback off

PROMPT ===========================================================================
PROMPT  Importing APEX application 100 (Customer Feedback) into workspace DEMO
PROMPT ===========================================================================

-- Re-target this import at workspace DEMO, application id 100, parsing schema
-- assigned to DEMO_SCHEMA. apex_application_install overrides the workspace/app
-- IDs embedded in the export so the same f100.sql installs cleanly across
-- DEV and PROD.
BEGIN
    apex_application_install.set_workspace('DEMO');
    apex_application_install.set_application_id(100);
    apex_application_install.set_application_alias('feedback');
    apex_application_install.generate_offset;
EXCEPTION
    WHEN OTHERS THEN
        -- Tolerate the case where workspace DEMO does not yet exist; the
        -- workflow will fail loudly on the next call and the operator will see
        -- a clear error in the action log.
        DBMS_OUTPUT.PUT_LINE('apex_application_install setup: ' || SQLERRM);
        RAISE;
END;
/

-- Begin a minimal APEX import. wwv_flow_imp.import_begin registers the import
-- context (version, build number, target workspace). The values below match a
-- bare-bones APEX 24.2 export.
BEGIN
    wwv_flow_imp.import_begin (
        p_version_yyyy_mm_dd     => '2024.10.07',
        p_release                => '24.2.0',
        p_default_workspace_id   => apex_application_install.get_workspace_id,
        p_default_application_id => 100,
        p_default_id_offset      => apex_application_install.get_offset,
        p_default_owner          => UPPER(USER)
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('import_begin failed: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('NOTE: this synthetic f100.sql is a placeholder.');
        DBMS_OUTPUT.PUT_LINE('Replace with a real APEX export -- see apex/README.md.');
        RAISE;
END;
/

-- Create a minimal application shell. A real export would now emit dozens of
-- wwv_flow_imp_shared.* and wwv_flow_imp_page.* calls. For the synthetic
-- placeholder we close the import immediately after creating the shell.
BEGIN
    wwv_flow_imp_shared.create_install_application (
        p_id                  => wwv_flow.g_flow_id,
        p_name                => 'Customer Feedback',
        p_alias               => 'feedback',
        p_application_group   => 0,
        p_owner               => UPPER(USER),
        p_authentication_id   => null,
        p_application_charset => 'AL32UTF8'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('create_install_application failed: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('NOTE: this synthetic f100.sql is a placeholder.');
        DBMS_OUTPUT.PUT_LINE('Replace with a real APEX export -- see apex/README.md.');
        RAISE;
END;
/

BEGIN
    wwv_flow_imp.import_end (p_auto_install_sup_obj => false);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Synthetic APEX import completed.');
    DBMS_OUTPUT.PUT_LINE('NOTE: this is a PLACEHOLDER app shell with no pages.');
    DBMS_OUTPUT.PUT_LINE('Replace apex/f100.sql with a real export to see UI.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('import_end failed: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
/

set define on
set verify on
set feedback on
