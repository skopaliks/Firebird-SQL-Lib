/******************************************************************************
* Stored Procedure : LIB$DDL_ChangeDataType
*
* Date    : 2020-10-30 
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.9
* Purpose : Change data type without data lost
*
* Revision History
* ================
* 
******************************************************************************/

-- Altering support procedures
SET TERM ^;

CREATE OR ALTER PROCEDURE LIB$DDL_ChangeDataType(
  RelationName RDB$Relation_Name NOT NULL, 
  FieldName RDB$Field_Name NOT NULL, 
  NewDataType VARCHAR(254) NOT NULL, 
  Exe Lib$BooleanF DEFAULT 0
)RETURNS(
  SQL VARCHAR(512)
)
AS
DECLARE tName VARCHAR(128);
DECLARE sql1 VARCHAR(512);
DECLARE sql2 VARCHAR(512);
DECLARE sql3 VARCHAR(512);
DECLARE isRep SMALLINT;  -- Flag that replication flag is already sets 
BEGIN
  tName = TRIM(SUBSTRING('tmp_x788_'||FieldName FROM 1 FOR 32));
  SQL = 'ALTER TABLE '||TRIM(RelationName)||' ALTER COLUMN '|| TRIM(FieldName)||' TO '||tName;
  SUSPEND;
  sql1 = SQL;
  SQL = 'ALTER TABLE '||TRIM(RelationName)||' ADD ' || FieldName || ' ' || NewDataType;
  SUSPEND;
  sql2 = SQL;
  SQL = 'UPDATE '||TRIM(RelationName)||' SET ' || FieldName || ' = ' || tName;
  SUSPEND;
  sql3 = SQL;
  SQL = 'ALTER TABLE ' || TRIM(RelationName) || ' DROP ' || tName;
  SUSPEND;
  IF(Exe>0)THEN BEGIN
    isRep = Rdb$Get_Context('USER_SESSION','DatabaseReplicationFlag');
    IF(isRep IS NULL)THEN Rdb$Set_Context('USER_SESSION','DatabaseReplicationFlag', 1);
    IN AUTONOMOUS TRANSACTION DO BEGIN
      EXECUTE STATEMENT sql1;
      EXECUTE STATEMENT sql2;
    END
    EXECUTE STATEMENT sql3 WITH AUTONOMOUS TRANSACTION;
    EXECUTE STATEMENT SQL WITH AUTONOMOUS TRANSACTION;
    IF(isRep IS NULL)THEN Rdb$Set_Context('USER_SESSION','DatabaseReplicationFlag', NULL);
  END
END
^

SET TERM ;^

