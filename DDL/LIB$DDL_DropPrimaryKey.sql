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
* 
******************************************************************************/

SET TERM ^;
CREATE OR ALTER PROCEDURE LIB$DDL_DropPrimaryKey(Relation RDB$Relation_Name NOT NULL, Exe Lib$BooleanF DEFAULT 0)
  RETURNS(SQL VARCHAR(512))
AS
DECLARE VARIABLE cn VARCHAR(500)=NULL;
BEGIN
  SELECT TRIM(rc.rdb$constraint_name)
    FROM rdb$Relation_Constraints RC LEFT JOIN RDB$Indices I ON RC.rdb$Index_Name=I.rdb$Index_Name
    WHERE I.rdb$Relation_Name=:Relation AND RC.rdb$Constraint_Type='PRIMARY KEY'
    INTO :cn;
  IF(cn IS NULL) THEN 
    EXCEPTION LIB$DDL_Exception 'Table '||Relation||' doen''t contain primary key';
  SQL='ALTER TABLE ' || TRIM(Relation) ||' DROP CONSTRAINT '||cn||';';    
  IF(Exe>0)THEN BEGIN
    EXECUTE STATEMENT SQL;
  END
  SUSPEND;
END
^
SET TERM ;^
