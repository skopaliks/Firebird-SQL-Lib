/******************************************************************************
*         : System for metadata distribution accross replication cluster
*
* Date    : 2017-09-20
* Author  : Slavomir Skopalik
* Server  : FB 2.5.7
* Purpose : 
*
* Revision History
******************************************************************************/

CREATE OR ALTER EXCEPTION REPL$DLL_Disconnect 'Replication exception:Force but planned diconecting';

SET TERM ^;

EXECUTE BLOCK AS
DECLARE ds VARCHAR(1000);
BEGIN
  -- Install this fearure only if IBReplicator is installed
  IF(NOT EXISTS(SELECT * FROM RDB$Relations WHERE RDB$Relation_Name='REPL$DATABASES'))THEN EXIT;
  -- Create table only if not exists
  IF(NOT EXISTS(SELECT * FROM RDB$Relations WHERE RDB$Relation_Name='REPL$DDL'))THEN BEGIN
  ds = '
CREATE TABLE REPL$DDL(
  id               INTEGER NOT NULL,
  DBNO             INTEGER,
  SQL              LIB$LargeText,
  TimeOut          SMALLINT NOT NULL,              -- Time after send Event and before hard kill in [ms]
  Kill_Connections LIB$BooleanF NOT NULL,
  Disconnect_After LIB$BooleanF NOT NULL,
  tDateUTC         Lib$TimestampUTC,
  Msg              LIB$LargeText,
  CONSTRAINT REPL$DDL_Pk PRIMARY KEY(id),
  CONSTRAINT REPL$DDL_REPL$Databases FOREIGN KEY (DBNO) REFERENCES Repl$Databases(DBNo) ON UPDATE CASCADE ON DELETE CASCADE
)
';
    EXECUTE STATEMENT ds;
    ds = 'CREATE GENERATOR REPL$DDL_id';
    EXECUTE STATEMENT ds;
  END
  ds = '
CREATE OR ALTER TRIGGER REPL$DDL_BIU FOR REPL$DDL BEFORE INSERT OR UPDATE AS
DECLARE Ex LIB$BooleanF;  -- Execute SQL
BEGIN
  IF(INSERTING)THEN BEGIN
    IF(new.id IS NULL)THEN new.id = NEXT VALUE FOR REPL$DDL_id;
    IF(EXISTS(SELECT * FROM REPL$DDL WHERE id=new.id))THEN EXIT;
    IF(new.TimeOut IS NULL)THEN new.TimeOut = 100; -- Default wait before kill 
    Ex = 1;
    
    IF(Ex>0)THEN BEGIN
      IN AUTONOMOUS TRANSACTION DO POST_EVENT(''REPL$METADATA_CHANGE'');
      IF(new.Kill_Connections>0)THEN BEGIN      
        Sleep(new.TimeOut);
        DELETE FROM MON$ATTACHMENTS WHERE MON$ATTACHMENT_ID <> CURRENT_CONNECTION;
      END
    END
  END
  IF(UPDATING)THEN BEGIN
  END
END';
  EXECUTE STATEMENT ds;
END
^

SET TERM ;^
          
  
  