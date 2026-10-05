/*=============================================================================
  Insurance HOL - ATTENDEE ACCESS CHECK  (read-only, no admin rights needed)
  How to run: Snowsight > Projects > Workspaces > + Add new > SQL file > paste > Run All.
  Every statement must succeed. Keep the output of query 1 - you'll paste your object
  names into the CoCo prompts.
=============================================================================*/
USE ROLE HOL_ATTENDEE_ROLE;
USE WAREHOUSE HOL_WH;

-- 1. Your object names (suffix = your user name, upper-cased, non A-Z/0-9/_ -> _) -------------
SET (MY_SUFFIX) = (SELECT REGEXP_REPLACE(UPPER(CURRENT_USER()), '[^A-Z0-9_]', '_'));
SELECT CURRENT_USER()                                              AS me,
       $MY_SUFFIX                                                  AS my_suffix,
       'HOL_INSURANCE_DB.LAB.INSURANCE_ANALYTICS_SV_' || $MY_SUFFIX AS my_semantic_view,
       'HOL_INSURANCE_DB.LAB.INSURANCE_CLAIMS_AGENT_' || $MY_SUFFIX AS my_agent;

-- 2. Defaults - CoCo in Snowsight and Cortex Agents run as your DEFAULT role + warehouse --------
SET ME = CURRENT_USER();
DESC USER IDENTIFIER($ME) ->> SELECT "property", "value",
    IFF("value" IN ('HOL_ATTENDEE_ROLE', 'HOL_WH'), 'OK', 'ASK YOUR ADMIN') AS status
  FROM $1 WHERE "property" IN ('DEFAULT_ROLE', 'DEFAULT_WAREHOUSE');

-- 3. Read access to the sample data ----------------------------------------------------------
-- Expected: CLAIM_NOTES 42, CLAIMS 36, CUSTOMER_EMAILS 45, POLICIES 45, POLICYHOLDERS 45, RISK_ASSESSMENTS 45
SELECT 'POLICYHOLDERS' AS table_name, COUNT(*) AS row_count FROM HOL_INSURANCE_DB.DATA.POLICYHOLDERS UNION ALL
SELECT 'POLICIES',         COUNT(*) FROM HOL_INSURANCE_DB.DATA.POLICIES         UNION ALL
SELECT 'CLAIMS',           COUNT(*) FROM HOL_INSURANCE_DB.DATA.CLAIMS           UNION ALL
SELECT 'CLAIM_NOTES',      COUNT(*) FROM HOL_INSURANCE_DB.DATA.CLAIM_NOTES      UNION ALL
SELECT 'CUSTOMER_EMAILS',  COUNT(*) FROM HOL_INSURANCE_DB.DATA.CUSTOMER_EMAILS  UNION ALL
SELECT 'RISK_ASSESSMENTS', COUNT(*) FROM HOL_INSURANCE_DB.DATA.RISK_ASSESSMENTS
ORDER BY table_name;

-- 4. Create privileges in the shared LAB schema ------------------------------------------------
-- Expected: CREATE AGENT, CREATE CORTEX SEARCH SERVICE, CREATE SEMANTIC VIEW, CREATE TABLE, CREATE VIEW, USAGE
SHOW GRANTS ON SCHEMA HOL_INSURANCE_DB.LAB ->> SELECT "privilege" FROM $1
  WHERE "grantee_name" = 'HOL_ATTENDEE_ROLE' ORDER BY 1;
