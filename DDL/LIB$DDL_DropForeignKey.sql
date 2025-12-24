/******************************************************************************
* Stored Procedure : LIB$DDL_DropForeignKey
*
* Date    : 2018-10-24 
* Author  : Slavomir Skopalik
* Server  : Firebird 5.0.3
* Purpose : Drop Foreign Key for given table and field
*
* Revision History
* ================
* 2025-12-25 S.Skopalik   Ability to avoid exception in case that FK not exists 
******************************************************************************/

SET TERM ^;
CREATE OR ALTER PROCEDURE LIB$DDL_DropForeignKey(Relation RDB$Relation_Name NOT NULL, Field RDB$Field_Name NOT NULL, Exe Lib$BooleanF DEFAULT 0, NoExceptions BOOLEAN DEFAULT FALSE)
  RETURNS(SQL VARCHAR(512))
AS
DECLARE VARIABLE cn VARCHAR(500)=NULL;
DECLARE VARIABLE ConsName VARCHAR(500) = NULL;
BEGIN
  FOR SELECT TRIM(C.RDB$CONSTRAINT_NAME)
    FROM RDB$INDICES I
    LEFT JOIN RDB$INDEX_SEGMENTS S ON S.rdb$index_name=I.rdb$index_name
    LEFT JOIN RDB$RELATION_CONSTRAINTS C ON C.rdb$index_name=I.rdb$index_name
    WHERE I.RDB$RELATION_NAME = :Relation AND C.RDB$CONSTRAINT_TYPE='FOREIGN KEY'
    AND S.rdb$field_name = :Field
    INTO :ConsName
    DO BEGIN
      SQL = 'ALTER TABLE '||TRIM(Relation)||' DROP CONSTRAINT '||ConsName;
      IF(Exe>0)THEN BEGIN
        EXECUTE STATEMENT SQL;
      END
      SUSPEND;
  END
  IF(ConsName IS NULL AND NoExceptions = FALSE) THEN EXCEPTION LIB$DDL_Exception 'Cannot fond FK for table('||TRIM(Relation)||') and field('||Field||')';
END
^
SET TERM ;^

