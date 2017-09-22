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
DECLARE ds VARCHAR(4000);
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
DECLARE usr    VARCHAR(63);                          -- Admin User (see replication manual)
DECLARE psw    VARCHAR(63);                          -- Admin password (see replication manual)
DECLARE DBPath TYPE OF COLUMN Repl$Databases.DBPath; -- Source DB Name (full path including server name)
DECLARE CurrentDB VARCHAR(1000);
DECLARE RemoteDB  VARCHAR(1000);
DECLARE ds VARCHAR(4000);
BEGIN
  IF(INSERTING)THEN BEGIN
    IF(new.id IS NULL)THEN new.id = NEXT VALUE FOR REPL$DDL_id;
    IF(new.tDateUTC IS NULL)THEN new.tDateUTC = GetExactTimestampUTC();
    IF(EXISTS(SELECT * FROM REPL$DDL WHERE id=new.id))THEN EXIT;
    IF(new.TimeOut IS NULL)THEN new.TimeOut = 100; -- Default wait before kill 
    Ex = 1;
    IF(new.DBNO IS NOT NULL)THEN BEGIN      
      CurrentDB = (SELECT ComputerName()||'':''||MON$Database_Name FROM MON$Database);
      SELECT UPPER(DB.DBPath), DB.Adminuser, Ibr_Decodepassword(DB.Adminpassword) FROM Repl$Databases DB WHERE DB.DBNo = new.DBNo INTO :DBPath, :usr, :psw;
      ds = ''SELECT ComputerName()||'''':''''||MON$Database_Name FROM MON$Database'';      
      EXECUTE STATEMENT ds ON EXTERNAL DBPath AS USER usr PASSWORD psw INTO :RemoteDB;      
      IF(RemoteDB IS DISTINCT FROM CurrentDB)THEN Ex=0;      
      new.Msg = GetExactTimestampUTC()||'' '';
      IF(Ex>0)THEN new.Msg = new.Msg||''Node Matched''; ELSE new.Msg = new.Msg||''Node Skipped'';
      new.Msg = new.Msg||'' ''||CurrentDB;
    END
    IF(Ex>0)THEN BEGIN
      IN AUTONOMOUS TRANSACTION DO POST_EVENT(''REPL$METADATA_CHANGE'');
      IF(new.Kill_Connections>0)THEN BEGIN      
        Sleep(new.TimeOut);
        DELETE FROM MON$ATTACHMENTS WHERE MON$ATTACHMENT_ID <> CURRENT_CONNECTION;
      END
      IF(new.Disconnect_After>0)THEN BEGIN  -- Disconect will rolback transaction -> all action must be in separate one
        IN AUTONOMOUS TRANSACTION DO BEGIN
          EXECUTE STATEMENT new.SQL;
          INSERT INTO REPL$DDL(id) VALUES(new.id);  -- Ensure that DDL will executed only one time
        END
        EXCEPTION REPL$DLL_Disconnect ''REPL$DDL.id:''||new.id;
      END ELSE BEGIN
        EXECUTE STATEMENT new.SQL;
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
          
  
  