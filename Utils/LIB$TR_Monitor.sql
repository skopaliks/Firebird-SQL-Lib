/******************************************************************************
*         : Very simple but useful utility to undestand who spamming DB by
*           transactions
*
* Date    : 2017-09-07
* Author  : Slavomir Skopalik
* Server  : FB 2.5
* Purpose : Log specific number of commited and also rollbacked transactions
*
* Revision History
******************************************************************************/

RECREATE Table LIB$Transactions_Log (
	tDateUTC            Lib$TimestampUTC NOT NULL,
  RollBacked          SMALLINT         NOT NULL,
	Log_REMOTE_PROTOCOL VARCHAR(10)      NOT NULL,
  Log_REMOTE_ADDRESS  VARCHAR(255)     NOT NULL,
	Log_CURRENT_USER    VARCHAR(31)      NOT NULL,
	Log_CURRENT_ROLE    VARCHAR(31)      NOT NULL,
	Log_SESSION_ID      BIGINT           NOT NULL,
	Log_TRANSACTION_ID  BIGINT           NOT NULL,
	Log_ISOLATION_Mode  SMALLINT         NOT NULL,
	Log_REMOTE_PROCESS  VARCHAR(255),
	usr_msg             VARCHAR(511)
);

GRANT INSERT ON LIB$Transactions_Log TO PUBLIC;

SET TERM ^;

CREATE OR ALTER TRIGGER LIB$Transactions_Log_BI FOR MON_Transactions
ACTIVE BEFORE INSERT POSITION 2
AS
BEGIN
  -- Just to pass Elekt Labs replication check
  -- IF(Rdb$Get_Context(''USER_SESSION'',''DatabaseReplicationFlag'') IS NOT NULL) THEN EXIT;
  new.tDateUTC = GetExactTimestampUTC();
  new.Log_REMOTE_PROTOCOL = RDB$GET_CONTEXT('SYSTEM', 'NETWORK_PROTOCOL');
  new.Log_REMOTE_ADDRESS = RDB$GET_CONTEXT('SYSTEM', 'CLIENT_ADDRESS');
END


EXECUTE BLOCK AS
DECLARE ds VARCHAR(500);
BEGIN
  -- Create sequence generator if missing
  ds = 'CREATE GENERATOR LIB$Transactions_Log_Counter;';
  BEGIN
    EXECUTE STATEMENT ds;
  WHEN ANY DO BEGIN END
  END
END
^


SET TERM ;^ 