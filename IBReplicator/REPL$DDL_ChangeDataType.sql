/******************************************************************************
* Stored Procedure : REPL$DDL_ChangeDataType
*
* Date    : 2022-11-20 
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.9
* Purpose : Change data type without data lost in replication cluster
*
* Revision History
* ================
* 2022-11-22  SkopalikS   Set replication flag for DML
******************************************************************************/

SET TERM ^;

CREATE OR ALTER PROCEDURE REPL$DDL_ChangeDataType(
  RelationName   RDB$Relation_Name NOT NULL, 
  FieldName      RDB$Field_Name NOT NULL, 
  NewDataType    VARCHAR(254) NOT NULL,
  DropDependency Lib$BooleanF DEFAULT 0
)
AS
DECLARE n INTEGER;
DECLARE isRep SMALLINT;  -- Replication flag is already sets
BEGIN
  isRep = Rdb$Get_Context('USER_SESSION','DatabaseReplicationFlag');
  IF(isRep IS NULL)THEN Rdb$Set_Context('USER_SESSION','DatabaseReplicationFlag', 1);
  FOR SELECT isDML, SQL FROM LIB$DDL_ChangeDataType(:RelationName, :FieldName, :NewDataType, 0, :DropDependency) AS CURSOR C1 DO BEGIN
    IF(C1.isDML > 0)THEN BEGIN
      SELECT COUNT(*) FROM Repl$WaitForRound(500) INTO n;      
      EXECUTE STATEMENT C1.SQL WITH AUTONOMOUS TRANSACTION;      
    END ELSE BEGIN
      IN AUTONOMOUS TRANSACTION DO BEGIN
        INSERT INTO Repl$DDL(SQL) VALUES(C1.SQL);
      END
    END
  END
  IF(isRep IS NULL)THEN Rdb$Set_Context('USER_SESSION','DatabaseReplicationFlag', NULL);
END
^

SET TERM ;^

