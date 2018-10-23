/******************************************************************************
* Stored Procedure : MASA$ExtractProcedure
*
* Date    : 2017-07-29
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.7
* Purpose : Extract metadata for storage procedure
*
* Revision History
* ================
* 2017-09-14 - S.Skopalik: Ability to return empty procedure body
* 2017-09-17 - S.Skopalik: Renamed from MASA$ExtractProcedure to LIB$CMP_ExtractProcedure
* 2018-08-14 - J.Kejnar: Added comments extracting
******************************************************************************/
SET TERM ^;

CREATE OR ALTER PROCEDURE LIB$CMP_ExtractProcedure(SPName RDB$Procedure_Name NOT NULL, EmptyBody LIB$BooleanF
)RETURNS(
  DDL    LIB$LargeText,
  IsBody LIB$BooleanF,    -- Now is returning procedure body
  IsDrop Lib$BooleanF,    -- Now is returning drop statement
  IsComment LIB$BooleanF,  -- Now is returning procedure comment or procedure's parameters comments
  IsGrant LIB$BooleanF,  -- Now is returning Grant statement for privilege with procedure name as RDB$RELATION_NAME
  IsRevoke  LIB$BooleanF  -- Now is returning Revoke statement for privilege with procedure name as RDB$RELATION_NAME
)
AS
DECLARE CRLF       LIB$CRLF;
DECLARE pt         INTEGER;
DECLARE pt_old     INTEGER=-1;
DECLARE param_ddl  VARCHAR(500);
DECLARE cnt        INTEGER=0;
DECLARE Source     LIB$LargeText;
DECLARE usr        TYPE OF COLUMN RDB$User_Privileges.RDB$User;
DECLARE priv       TYPE OF COLUMN RDB$User_Privileges.RDB$Privilege;
DECLARE usr_t      VARCHAR(63);
DECLARE dsc        TYPE OF COLUMN RDB$Procedures.RDB$DESCRIPTION;
DECLARE dscp       TYPE OF COLUMN RDB$Procedure_Parameters.RDB$DESCRIPTION;
DECLARE param_name TYPE OF COLUMN RDB$Procedure_Parameters.RDB$PARAMETER_NAME;
BEGIN
  IF(NOT EXISTS (SELECT * FROM RDB$Procedures WHERE RDB$PROCEDURE_NAME=:SPName)) THEN
    EXCEPTION Lib$Cmp_Exception 'Procedure ' || :SPName || ' not found.';
  DDL = 'CREATE OR ALTER PROCEDURE '||SPName;
  FOR SELECT
    pn.Rdb$Parameter_Type,
    TRIM(RDB$PARAMETER_NAME)||' '||
      COALESCE('TYPE OF COLUMN '||TRIM(RDB$RELATION_NAME)||'.'||TRIM(RDB$FIELD_NAME),
        (SELECT DataType FROM LIB$CMP_GetFieldDataType(pn.RDB$FIELD_SOURCE))
      )||
      ' '||TRIM(IIF(RDB$NULL_FLAG=1, 'NOT NULL',''))||
      COALESCE((SELECT ' '||DefaultExpresion FROM LIB$CMP_GetFieldDataType(pn.RDB$FIELD_SOURCE))||' ','')
    FROM RDB$PROCEDURE_PARAMETERS pn
    WHERE RDB$PROCEDURE_NAME=:SPName
    ORDER BY pn.Rdb$Parameter_Type, pn.Rdb$Parameter_Number
    INTO :pt, :param_ddl DO BEGIN
    IF(pt_old=-1 AND pt=0)THEN BEGIN
      DDL = DDL ||'(';
      pt_old = 0;
    END
    IF(pt_old=0 AND pt=1)THEN BEGIN
      DDL = DDL ||')';
    END
    IF(pt_old IN(-1,0) AND pt=1)THEN BEGIN
      DDL = DDL || CRLF || 'RETURNS(';
      pt_old = 1;
      cnt = 0;
    END
    IF(cnt>0)THEN DDL = DDL||',';
    DDL = DDL||CRLF;
    DDL = DDL||'  '||param_ddl;
    cnt = cnt + 1;
  END
  IF(pt_old<>-1)THEN DDL = DDL ||')';
  DDL = DDL || CRLF || 'AS' || CRLF;
  IF(EmptyBody = 0)THEN BEGIN
    SELECT RDB$PROCEDURE_SOURCE, RDB$DESCRIPTION FROM RDB$Procedures WHERE RDB$Procedure_Name = :SPName
    INTO :Source, :dsc;
   END ELSE BEGIN
    Source =           'BEGIN '||CRLF;
    Source = Source || ' EXCEPTION LIB$CMP_Exception ''Procedure '||SPName||' is not implemented'';'||CRLF;
    Source = Source || 'END';
  END
  IsBody = 1;
  DDL = DDL || Source;
  SUSPEND;

  -- Extract DROP statement
  IsDrop = 1;
  IsBody = 0;
  DDL =  'DROP PROCEDURE ' || SPName;
  SUSPEND;

  -- Extract procedure comments
  IsComment = 1;
  IsDrop = 0;
  IF(:dsc IS NOT NULL)THEN BEGIN
    DDL = 'COMMENT ON PROCEDURE ' || SPName || ' IS ''' || :dsc || '''';
    SUSPEND;
  END
  FOR SELECT
    pn.RDB$Description,
    pn.RDB$PARAMETER_NAME
    FROM RDB$PROCEDURE_PARAMETERS pn
    WHERE RDB$PROCEDURE_NAME=:SPName
    INTO :dscp, :param_name
    DO BEGIN
       IF(:dscp IS NOT NULL) THEN BEGIN
        DDL = 'COMMENT ON PARAMETER ' || SPName || '.' || TRIM(:param_name) || ' IS ''' || :dscp || '''';
        SUSPEND;
       END
    END

  -- Extract procedure rights
  IsGrant = 1;
  IsComment = 0;
  FOR 
    SELECT 
      RDB$User, 
      RDB$Privilege, 
      (SELECT UserType FROM LIB$CMP_GetUserType(RDB$User_Privileges.RDB$USER_TYPE))
      FROM RDB$User_Privileges WHERE RDB$Relation_Name = :SPName AND RDB$OBJECT_TYPE = 5 
      INTO :usr, :priv, :usr_t
    DO BEGIN
    IF(priv='X')THEN BEGIN
      DDL = 'GRANT EXECUTE ON PROCEDURE '||SPName||' TO '||usr_t||' '||TRIM(usr);
      SUSPEND;
    END    
  END

  -- Extract Revoke statements
  IsRevoke = 1;
  IsGrant = 0;
  FOR 
    SELECT 
      RDB$User, 
      RDB$Privilege, 
      (SELECT UserType FROM LIB$CMP_GetUserType(RDB$User_Privileges.RDB$USER_TYPE))
      FROM RDB$User_Privileges WHERE RDB$Relation_Name = :SPName AND RDB$OBJECT_TYPE = 5 
      INTO :usr, :priv, :usr_t
    DO BEGIN
    IF(priv='X')THEN BEGIN
      DDL = 'REVOKE EXECUTE ON PROCEDURE '||SPName||' FROM '||usr_t||' '||TRIM(usr);
      SUSPEND;
    END    
  END

  IsRevoke = 0;
END
^
SET TERM ;^
