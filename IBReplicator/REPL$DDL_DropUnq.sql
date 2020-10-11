/******************************************************************************
* Stored Procedure : REPL$DDL_DropUnq
*
* Date    : 2020-10-10
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.9
* Purpose : Drop all unique constraint on given column  and replicate it
*
* Revision History
* ================
*
******************************************************************************/
SET TERM ^;

CREATE OR ALTER PROCEDURE REPL$DDL_DropUnq(Relation RDB$Relation_Name NOT NULL, Field RDB$Field_Name NOT NULL)
AS
BEGIN
  INSERT INTO Repl$DDL(Kill_Connections, Disconnect_After, SQL)
    SELECT 1, 1, SQL FROM LIB$DDL_DropUnq(:Relation, :Field, 0, 1);
END
^

SET TERM ;^

