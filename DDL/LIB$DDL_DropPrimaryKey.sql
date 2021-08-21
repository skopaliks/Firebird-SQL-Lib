/******************************************************************************
* Stored Procedure : LIB$DDL_DropPrimaryKey
*
* Date    : 2018-10-24 
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.7
* Purpose : Drop Primary Key for given table
*
* Revision History
* ================
* 2021-08-21 - S.Skopalik:  Drop also existing FKs if exists
******************************************************************************/

SET TERM ^;
CREATE OR ALTER PROCEDURE LIB$DDL_DropPrimaryKey(Relation RDB$Relation_Name NOT NULL, Exe Lib$BooleanF DEFAULT 0)
  RETURNS(SQL VARCHAR(512))
AS
DECLARE VARIABLE cn VARCHAR(500)=NULL;
BEGIN
  -- Get primary key constraint name
  SELECT TRIM(rc.rdb$constraint_name)
    FROM rdb$Relation_Constraints RC LEFT JOIN RDB$Indices I ON RC.rdb$Index_Name=I.rdb$Index_Name
    WHERE I.rdb$Relation_Name=:Relation AND RC.rdb$Constraint_Type='PRIMARY KEY'
    INTO :cn;
  IF(cn IS NULL) THEN 
    EXCEPTION LIB$DDL_Exception 'Table '||Relation||' doen''t contain primary key';
  -- Drop all FK if exists
  FOR SELECT 'ALTER TABLE '||TRIM(C.RDB$Relation_Name)||' DROP CONSTRAINT ' || TRIM(RC.RDB$Constraint_Name) SQL
    FROM RDB$REF_CONSTRAINTS RC, RDB$RELATION_CONSTRAINTS C
    WHERE RC.RDB$Constraint_Name = C.RDB$Constraint_Name AND RC.RDB$Const_Name_Uq = :cn
    INTO SQL DO BEGIN
    IF(Exe>0)THEN BEGIN
      EXECUTE STATEMENT SQL;
    END
    SUSPEND;
  END
  -- Finally drop primary key
  SQL='ALTER TABLE ' || TRIM(Relation) ||' DROP CONSTRAINT '||cn||';';    
  IF(Exe>0)THEN BEGIN
    EXECUTE STATEMENT SQL;
  END
  SUSPEND;
END
^
SET TERM ;^
