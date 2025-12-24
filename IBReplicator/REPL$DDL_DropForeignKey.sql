/******************************************************************************
* Stored Procedure : REPL$DDL_DropForeignKey
*
* Date    : 2020-03-23
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.7
* Purpose : Drop Foreign Key for given table and field on all nodes
*
* Revision History
* ================
* 2025-12-25 S.Skopalik   Ability to avoid exception in case that FK not exists 
******************************************************************************/

SET TERM ^;
CREATE OR ALTER PROCEDURE REPL$DDL_DropForeignKey(Relation RDB$Relation_Name NOT NULL, Field RDB$Field_Name NOT NULL, NoExceptions BOOLEAN DEFAULT FALSE)
AS
BEGIN
  INSERT INTO Repl$DDL(Kill_Connections, Disconnect_After, SQL)
    SELECT 1, 1, SQL FROM LIB$DDL_DropForeignKey(:Relation, :Field, 0, :NoExceptions);
END
^
SET TERM ;^

