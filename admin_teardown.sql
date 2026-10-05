/*=============================================================================
  Insurance HOL - ADMIN TEARDOWN - run after the lab, as a user who can use SECURITYADMIN
  and SYSADMIN.  How to run: Workspaces > SQL file > paste > Run All.

  - Every user holding HOL_ATTENDEE_ROLE has DEFAULT_ROLE / DEFAULT_WAREHOUSE UNSET if they
    still point at HOL_ATTENDEE_ROLE / HOL_WH (pre-lab defaults were not recorded; re-set any
    defaults your organisation requires afterwards). Users whose defaults changed are left alone.
  - Drops HOL_INSURANCE_DB (sample data AND every attendee's semantic view / agent in LAB),
    HOL_WH and HOL_ATTENDEE_ROLE. Ask attendees to export anything worth keeping first.
  - Account parameters reviewed in setup section 1 are not changed.
=============================================================================*/

-- 1. Reset attendees + revoke the role (SECURITYADMIN) ---------------------------------
USE ROLE SECURITYADMIN;
USE WAREHOUSE HOL_WH;          -- granted to SECURITYADMIN by admin_setup.sql
EXECUTE IMMEDIATE $$
DECLARE
  usr VARCHAR;
  def_role VARCHAR;
  def_wh   VARCHAR;
  grantees RESULTSET;
  props    RESULTSET;
  report VARCHAR DEFAULT '';
BEGIN
  grantees := (SHOW GRANTS OF ROLE HOL_ATTENDEE_ROLE);
  FOR g IN grantees DO
    IF (g."granted_to" = 'USER') THEN
      usr := '"' || g."grantee_name" || '"';
      props := (DESCRIBE USER IDENTIFIER(:usr));
      def_role := NULL;
      def_wh := NULL;
      FOR p IN props DO
        IF (p."property" = 'DEFAULT_ROLE')      THEN def_role := p."value"; END IF;
        IF (p."property" = 'DEFAULT_WAREHOUSE') THEN def_wh   := p."value"; END IF;
      END FOR;
      IF (UPPER(def_role) = 'HOL_ATTENDEE_ROLE') THEN ALTER USER IDENTIFIER(:usr) UNSET DEFAULT_ROLE;      END IF;
      IF (UPPER(def_wh)   = 'HOL_WH')            THEN ALTER USER IDENTIFIER(:usr) UNSET DEFAULT_WAREHOUSE; END IF;
      REVOKE ROLE HOL_ATTENDEE_ROLE FROM USER IDENTIFIER(:usr);
      report := report || usr || ' reset' || CHR(10);
    END IF;
  END FOR;
  RETURN report;
EXCEPTION
  WHEN OTHER THEN
    RETURN 'HOL_ATTENDEE_ROLE not found - nothing to reset (' || SQLERRM || ')';
END;
$$;

-- 2. Drop lab objects --------------------------------------------------------------------
USE ROLE SYSADMIN;
DROP DATABASE  IF EXISTS HOL_INSURANCE_DB;
DROP WAREHOUSE IF EXISTS HOL_WH;
USE ROLE SECURITYADMIN;
DROP ROLE IF EXISTS HOL_ATTENDEE_ROLE;
