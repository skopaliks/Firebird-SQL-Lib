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
	bDateUTC            Lib$TimestampUTC NOT NULL,  -- When transaction start
  eDateUTC            Lib$TimestampUTC NOT NULL,  -- When transaction finished
  RollBacked          SMALLINT         NOT NULL,
	Log_REMOTE_PROTOCOL VARCHAR(10)      NOT NULL,
  Log_REMOTE_ADDRESS  VARCHAR(255)     NOT NULL,
	Log_CURRENT_USER    VARCHAR(31)      NOT NULL,
	Log_CURRENT_ROLE    VARCHAR(31)      NOT NULL,
	Log_SESSION_ID      BIGINT           NOT NULL,
	Log_TRANSACTION_ID  BIGINT           NOT NULL,
	Log_ISOLATION_Mode  SMALLINT         NOT NULL,
	Log_REMOTE_PROCESS  VARCHAR(255),
	usr_msg             VARCHAR(511)                -- For debuging, use context variable 'USER_TRANSACTION'.'LIB$Transactions_Log_usr_msg'
);

GRANT INSERT ON LIB$Transactions_Log TO PUBLIC;

SET TERM ^;

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

CREATE OR ALTER TRIGGER LIB$Transactions_Log_BI FOR LIB$Transactions_Log
ACTIVE BEFORE INSERT POSITION 2
AS
BEGIN
  -- Just to pass Elekt Labs replication check
  -- IF(Rdb$Get_Context('USER_SESSION','DatabaseReplicationFlag') IS NOT NULL) THEN EXIT;
  new.bDateUTC            = RDB$Get_Context('USER_TRANSACTION','LIB$Transactions_Log_bDateUTC'); 
  new.eDateUTC            = GetExactTimestampUTC();
  new.Log_REMOTE_PROTOCOL = RDB$GET_CONTEXT('SYSTEM', 'NETWORK_PROTOCOL');
  new.Log_REMOTE_ADDRESS  = RDB$GET_CONTEXT('SYSTEM', 'CLIENT_ADDRESS');
  new.Log_CURRENT_USER    = CURRENT_USER;
  new.Log_CURRENT_ROLE    = CURRENT_ROLE;
  new.Log_SESSION_ID      = CURRENT_CONNECTION;
  new.Log_TRANSACTION_ID  = CURRENT_TRANSACTION;
  new.Log_ISOLATION_Mode  = RDB$GET_CONTEXT('SYSTEM', 'ISOLATION_LEVEL');
  new.Log_REMOTE_PROCESS  = (SELECT MON$Remote_Process FROM MON$Attachments WHERE MON$ATTACHMENT_ID = CURRENT_CONNECTION);
  new.usr_msg             = RDB$Get_Context('USER_TRANSACTION','LIB$Transactions_Log_usr_msg');
END
^

CREATE OR ALTER TRIGGER LIB$TR_Monitor_Start ACTIVE ON TRANSACTION START POSITION 1
AS
DECLARE gn BIGINT;
BEGIN
  -- Just to pass Elekt Labs replication check
  -- IF(Rdb$Get_Context('USER_SESSION','DatabaseReplicationFlag') IS NOT NULL) THEN EXIT;
  gn = GEN_ID(LIB$Transactions_Log_Counter,-1);
  IF(gn>0)THEN
    RDB$Set_Context('USER_TRANSACTION','LIB$Transactions_Log_bDateUTC',GetExactTimestampUTC());
END
^

CREATE OR ALTER TRIGGER LIB$TR_Monitor_Commit ACTIVE ON TRANSACTION COMMIT POSITION 32761
AS
BEGIN
  IF(RDB$Get_Context('USER_TRANSACTION','LIB$Transactions_Log_bDateUTC') IS NOT NULL)THEN
    INSERT INTO LIB$Transactions_Log(Rollbacked) VALUES(0);
END
^

CREATE OR ALTER TRIGGER LIB$TR_Monitor_Rollback ACTIVE ON TRANSACTION ROLLBACK POSITION 32761
AS
BEGIN
  IF(RDB$Get_Context('USER_TRANSACTION','LIB$Transactions_Log_bDateUTC') IS NOT NULL)THEN
    IN AUTONOMOUS TRANSACTION DO
      INSERT INTO LIB$Transactions_Log(Rollbacked) VALUES(1);
END
^

SET TERM ;^

COMMIT;
