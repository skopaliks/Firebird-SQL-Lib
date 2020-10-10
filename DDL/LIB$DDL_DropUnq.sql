/******************************************************************************
* Stored Procedure : LIB$DDL_DropUnq
*
* Date    : 2017-09-18
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.7
* Purpose : Drop all unique constraint on given column
*
* Revision History
* ================
* 2018-10-24 - S.Skopalik   Added restriction NOT NULL for input parameters
* 2020-10-10 - S.Skopalik   Added option to do not raise exception 
******************************************************************************/
SET TERM ^;

CREATE OR ALTER PROCEDURE LIB$DDL_DropUnq(Relation RDB$Relation_Name NOT NULL, Field RDB$Field_Name NOT NULL, Exe Lib$BooleanF DEFAULT 0, NoExceptions Lib$BooleanF DEFAULT 0)
  RETURNS(SQL VARCHAR(512))
AS
DECLARE VARIABLE cn VARCHAR(500)=NULL;
DECLARE VARIABLE consName VARCHAR(500) = NULL;
BEGIN
  FOR SELECT TRIM(C.RDB$CONSTRAINT_NAME)
    FROM RDB$INDICES I
    LEFT JOIN RDB$INDEX_SEGMENTS S ON S.rdb$index_name=I.rdb$index_name
    LEFT JOIN RDB$RELATION_CONSTRAINTS C ON C.rdb$index_name=I.rdb$index_name
    WHERE I.RDB$RELATION_NAME = :Relation AND C.RDB$CONSTRAINT_TYPE='UNIQUE'
    AND S.rdb$field_name = :Field
    INTO :consName
    DO BEGIN
      SQL = 'ALTER TABLE '||TRIM(Relation)||' DROP CONSTRAINT '||consName;
      IF(Exe>0)THEN BEGIN
        EXECUTE STATEMENT SQL;
      END
      SUSPEND;
  END
  IF(consName IS NULL AND NoExceptions = 0)THEN 
    EXCEPTION LIB$DDL_Exception 'Cannot fond unique constrant(s) for table('||TRIM(Relation)||') and field('||TRIM(Field)||')';
END
^

SET TERM ;^

