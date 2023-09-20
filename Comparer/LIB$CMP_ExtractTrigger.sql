/******************************************************************************
* Stored Procedure : LIB$CMP_ExtractTrigger
*
* Date    : 2018-06-29
* Author  : Jaroslav Kejnar
* Server  : Firebird 2.5.8
* Purpose : Extract metadata for triggers
*
* Revision History
* ================
* 2020-04-30 S.Skopalik  - Fixed too many spaces in trigger comments
* 2022-11-22 S.Skopalik  - Added possibility to update table records with empty trigger
*                          in replication mode, add TRIM for improve output quality
* 2023-04-10 S.Skopalik  - Fixed Transaction roll back trigger extraction
* 2023-05-15 S.Skopalik  - Fixed missing space before ON ... triggers
* 2023-09-19 S.Skopalik  - Fixed wrong setting of flag IsSource and IsBody
******************************************************************************/
SET TERM ^;

CREATE OR ALTER PROCEDURE LIB$CMP_ExtractTrigger(TriggerName RDB$Trigger_Name NOT NULL, EmptyBody LIB$BooleanF
)RETURNS(
  DDL       LIB$LargeText,
  IsHeader  LIB$BooleanF,  -- Now is returning trigger declaration(header)
  IsBody    LIB$BooleanF,  -- Now is returning trigger body
  IsSource  LIB$BooleanF,  -- Now is returning trigger PSQL
  IsDrop    LIB$BooleanF,  -- Now is retuning drop statement
  IsComment LIB$BooleanF   -- Now is returning trigger description
)
AS
DECLARE CRLF                    LIB$CRLF;
DECLARE trigger_type            TYPE OF COLUMN RDB$Triggers.RDB$TRIGGER_TYPE;
DECLARE trigger_inactive        TYPE OF COLUMN RDB$Triggers.RDB$TRIGGER_INACTIVE;
DECLARE trigger_sequence        TYPE OF COLUMN RDB$Triggers.RDB$TRIGGER_SEQUENCE;
DECLARE Source                  LIB$LargeText;
DECLARE usr                     TYPE OF COLUMN RDB$User_Privileges.RDB$User;
DECLARE priv                    TYPE OF COLUMN RDB$User_Privileges.RDB$Privilege;
DECLARE usr_t                   VARCHAR(63);
DECLARE dsc                     TYPE OF COLUMN RDB$Triggers.RDB$DESCRIPTION;
BEGIN
  -- Extract trigger header
  DDL = 'CREATE OR ALTER TRIGGER '|| TRIM(TriggerName);
  SELECT RDB$Trigger_Type, RDB$Trigger_Inactive, RDB$Trigger_Sequence FROM RDB$Triggers WHERE RDB$Trigger_Name = :TriggerName
    INTO trigger_type, trigger_inactive, trigger_sequence;
  IF(trigger_type IS NULL) THEN EXCEPTION LIB$CMP_Exception 'Trigger ''' || TRIM(TriggerName) || ''' not found.';    
  IF(trigger_type IN (8192, 8193, 8194, 8195, 8196)) THEN
    DDL = DDL || ' ' || (SELECT TriggerType FROM LIB$CMP_GetTriggerType(:trigger_type));
   ELSE BEGIN
     DDL = DDL || ' FOR ' || (SELECT TRIM(RDB$Relation_Name) FROM RDB$Triggers WHERE RDB$Trigger_Name = :TriggerName);
     DDL = DDL || ' ' || TRIM( IIF( trigger_inactive = 1, 'INACTIVE', 'ACTIVE') );
     DDL = DDL || ' ' || (SELECT TriggerType FROM LIB$CMP_GetTriggerType(:trigger_type));
  END
  IF(trigger_sequence > 0) THEN
    DDL = DDL || ' POSITION ' || trigger_sequence;
  IsHeader = 1;
  SUSPEND;
  IsHeader = 0;
  
  -- Extract trigger header with body
  DDL = DDL || CRLF;
  IF(EmptyBody = 0)THEN BEGIN
    SELECT RDB$TRIGGER_SOURCE, RDB$DESCRIPTION FROM RDB$Triggers WHERE RDB$Trigger_Name = :TriggerName
        INTO :Source, :dsc;
    DDL = DDL || TRIM(Source);
  END
  ELSE
    DDL = DDL || 'AS' || CRLF || 
    'BEGIN' || CRLF ||
    '  IF(Rdb$Get_Context(''USER_SESSION'',''DatabaseReplicationFlag'') IS NOT NULL) THEN EXIT;' || CRLF || 
    '  EXCEPTION LIB$CMP_Exception ''Trigger '  || TRIM(TriggerName) || ' is not implemented'';' || CRLF || 
    'END';
  IsSource = 1;
  SUSPEND;
  IsSource = 0;

  -- Extract source (trigger body)
  IF(EmptyBody = 0) THEN BEGIN
    DDL = Source;
    IsBody = 1;
    SUSPEND;
    IsBody = 0;
  END
  
  -- Extract drop statement
  isDrop = 1;
  DDL = 'DROP TRIGGER ' || TriggerName;
  SUSPEND;
  isDrop = 0;

  -- Extract trigger comment
  IF(dsc IS NOT NULL)THEN BEGIN
    IsComment = 1;
    DDL = 'COMMENT ON TRIGGER ' || TRIM(TriggerName) || ' IS ''' || dsc || '''';
    SUSPEND;
  END
  IsComment = 0;

END
^
SET TERM ;^
