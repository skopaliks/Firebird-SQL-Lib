/******************************************************************************
* Database Trigger: REPL$DBConnect
*
* Date    : 2018-08-11
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.8
* Purpose : Set replication flag
*
* Revision History
* ================
*
******************************************************************************/

SET TERM ^;

CREATE OR ALTER TRIGGER MASA$DBConnect ON CONNECT POSITION 5
AS
BEGIN
  IF (USER LIKE 'REPL%') THEN 
    Rdb$Set_Context('USER_SESSION','DatabaseReplicationFlag',1);  -- Set replicaton flag
END
^

SET TERM ;^
