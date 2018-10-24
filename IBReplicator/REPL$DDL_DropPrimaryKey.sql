/******************************************************************************
* Stored Procedure : REPL$DDL_DropPrimaryKey
*
* Date    : 2018-10-24 
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.7
* Purpose : Drop Primary Key for given table on all nodes
*
* Revision History
* ================
* 
******************************************************************************/

SET TERM ^;
CREATE OR ALTER PROCEDURE REPL$DDL_DropPrimaryKey(Relation RDB$Relation_Name NOT NULL)  
AS
BEGIN
  INSERT INTO Repl$DDL(Kill_Connections, Disconnect_After, SQL)
    SELECT 1, 1, SQL FROM LIB$DDL_DropPrimaryKey(:Relation);
END
^
SET TERM ;^
