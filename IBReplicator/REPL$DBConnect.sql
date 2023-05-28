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
* 2023-05-14 SkopalikS    Add binding for TIEMSTAMP WITH TIME zone due IBReplicator not supporting them
******************************************************************************/

SET TERM ^;

CREATE OR ALTER TRIGGER REPL$DBConnect ON CONNECT POSITION 5
AS
BEGIN
  IF (USER LIKE 'REPL%') THEN BEGIN 
    Rdb$Set_Context('USER_SESSION','DatabaseReplicationFlag',1);      -- Set replicaton flag
    SET BIND OF TIMESTAMP WITH TIME ZONE TO CHAR CHARACTER SET ASCII; -- Compatibility binding CHAR. ASCII have to be set due bug in FB4.0.2 (https://github.com/FirebirdSQL/firebird/issues/7548)
  END
END
^

SET TERM ;^
