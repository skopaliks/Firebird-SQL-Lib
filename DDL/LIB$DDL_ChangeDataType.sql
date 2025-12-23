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
* 2020-11-01 - S.Skopalik    In case of dependency then empty procedure bodies
* 2022-11-20 - S.Skopalik    Add isDML flag to distinguish between DDL and DML statements, extend SQL length
* 2022-11-21 - S.Skopalik    Add support to empty triggers bodies
* 2024-10-17 - S.Skopalik    Fixed extraction of empty triggers
******************************************************************************/

SET TERM ^;

CREATE OR ALTER PROCEDURE LIB$DDL_ChangeDataType(
  RelationName   RDB$Relation_Name NOT NULL, 
  FieldName      RDB$Field_Name NOT NULL, 
  NewDataType    VARCHAR(254) NOT NULL, 
  Exe            Lib$BooleanF DEFAULT 0,
  DropDependency Lib$BooleanF DEFAULT 0
)RETURNS(
  SQL    LIB$LargeText,
  isDML  Lib$BooleanF
)
AS
DECLARE tName VARCHAR(128);
DECLARE sql1 VARCHAR(512);
DECLARE sql2 VARCHAR(512);
DECLARE sql3 VARCHAR(512);
DECLARE isRep SMALLINT;  -- Flag that replication flag is already sets
DECLARE D_Name VARCHAR(128);
DECLARE D_Type VARCHAR(128);
DECLARE tmp_id INTEGER; 
BEGIN
  DELETE FROM LIB$DDL_TempTable;
  isDML = 0;
  tmp_id = 0;
  IF(DropDependency>0)THEN BEGIN
    FOR SELECT T.rdb$Type_Name, D.rdb$Dependent_Name FROM RDB$Dependencies D, RDB$Types T
      WHERE D.rdb$depended_on_name = :RelationName AND D.rdb$field_name = :FieldName
      AND T.rdb$Field_Name = 'RDB$OBJECT_TYPE' AND T.rdb$Type = D.Rdb$Dependent_Type
      INTO D_Type, D_Name DO BEGIN
      SQL = NULL;
      IF(D_Type = 'PROCEDURE')THEN BEGIN   -- Empty procedures bodies
        INSERT INTO LIB$DDL_TempTable(id, SQL)
          VALUES(:tmp_id, (SELECT DDL FROM Lib$Cmp_Extractprocedure(:D_Name, 0) WHERE IsBody = 1));
        tmp_id = tmp_id + 1;
        SQL = (SELECT DDL FROM Lib$Cmp_Extractprocedure(:D_Name, 1) WHERE IsBody = 1);      
      END
      IF(D_Type = 'TRIGGER')THEN BEGIN   -- Empty triggers bodies
        INSERT INTO LIB$DDL_TempTable(id, SQL)
          VALUES(:tmp_id, (SELECT DDL FROM LIB$CMP_ExtractTrigger(:D_Name, 0) WHERE IsSource = 1));
        tmp_id = tmp_id + 1;
        SQL = (SELECT DDL FROM LIB$CMP_ExtractTrigger(:D_Name, 1) WHERE IsSource = 1);
      END
      IF(SQL IS NOT NULL)THEN BEGIN
        SUSPEND;
        IF(Exe>0)THEN BEGIN
          EXECUTE STATEMENT SQL WITH AUTONOMOUS TRANSACTION;
        END
      END
    END
  END
  tName = TRIM(SUBSTRING('tmp_x788_'||FieldName FROM 1 FOR 32));
  SQL = 'ALTER TABLE '||TRIM(RelationName)||' ALTER COLUMN '|| TRIM(FieldName)||' TO '||tName;
  SUSPEND;
  sql1 = SQL;
  SQL = 'ALTER TABLE '||TRIM(RelationName)||' ADD ' || TRIM(FieldName) || ' ' || NewDataType;
  SUSPEND;
  sql2 = SQL;
  isDML = 1;
  SQL = 'UPDATE '||TRIM(RelationName)||' SET ' || FieldName || ' = ' || tName;
  SUSPEND;
  sql3 = SQL;
  isDML = 0;
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
  FOR SELECT SQL FROM LIB$DDL_TempTable ORDER BY id INTO SQL DO BEGIN
    SUSPEND;
    IF(Exe>0)THEN BEGIN
      EXECUTE STATEMENT SQL WITH AUTONOMOUS TRANSACTION;
    END
  END
END
^

SET TERM ;^

