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
******************************************************************************/

-- Altering support procedures
SET TERM ^;

CREATE OR ALTER PROCEDURE LIB$DDL_ChangeDataType(
  RelationName   RDB$Relation_Name NOT NULL, 
  FieldName      RDB$Field_Name NOT NULL, 
  NewDataType    VARCHAR(254) NOT NULL, 
  Exe            Lib$BooleanF DEFAULT 0,
  DropDependency Lib$BooleanF DEFAULT 0
)RETURNS(
  SQL VARCHAR(512)
)
AS
DECLARE tName VARCHAR(128);
DECLARE sql1 VARCHAR(512);
DECLARE sql2 VARCHAR(512);
DECLARE sql3 VARCHAR(512);
DECLARE isRep SMALLINT;  -- Flag that replication flag is already sets
DECLARE D_Name VARCHAR(128);
DECLARE D_Type VARCHAR(128); 
BEGIN
  IF(DropDependency>0)THEN BEGIN
    FOR SELECT T.rdb$Type_Name, D.rdb$Dependent_Name FROM RDB$Dependencies D, RDB$Types T
      WHERE D.rdb$depended_on_name = :RelationName AND D.rdb$field_name = :FieldName
      AND T.rdb$Field_Name = 'RDB$OBJECT_TYPE' AND T.rdb$Type = D.Rdb$Dependent_Type
      INTO D_Type, D_Name DO BEGIN
      IF(D_Type = 'PROCEDURE')THEN BEGIN   -- Empty procedures bodies
        SQL = (SELECT DDL FROM Lib$Cmp_Extractprocedure(:D_Name, 1) WHERE IsBody = 1);
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

