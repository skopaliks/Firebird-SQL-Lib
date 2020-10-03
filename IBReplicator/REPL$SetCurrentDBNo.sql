/******************************************************************************
* Stored Procedure : REPL$REPL$SetCurrentDBNo
*
* Date    : 2020-10-03 
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.9
* Purpose : Find node number and store into context variable
*
* Revision History
* ================
* 
******************************************************************************/

SET TERM ^;
CREATE OR ALTER PROCEDURE REPL$SetCurrentDBNo  
AS
DECLARE CurrentDB VARCHAR(1000);
DECLARE RemoteDB  VARCHAR(1000);
DECLARE ds        VARCHAR(4000);
DECLARE usr       VARCHAR(63);                          -- Admin User (see replication manual)
DECLARE psw       VARCHAR(63);                          -- Admin password (see replication manual)
DECLARE DBPath    TYPE OF COLUMN Repl$Databases.DBPath; -- Source DB Name (full path including server name)
DECLARE DBNo      TYPE OF COLUMN Repl$Databases.DBNo;
BEGIN
  IF(Rdb$Get_Context('USER_SESSION','REPL$CURRENTDBNO')IS NOT NULL)THEN EXIT;
  CurrentDB = (SELECT ComputerName()||':'||MON$Database_Name FROM MON$Database);
  FOR SELECT DB.DBNo, UPPER(DB.DBPath), DB.Adminuser, Ibr_Decodepassword(DB.Adminpassword) FROM Repl$Databases DB
    INTO DBNo, DBPath, usr, psw
    DO BEGIN
    ds = 'SELECT ComputerName()||'':''||MON$Database_Name FROM MON$Database';
    BEGIN      
      EXECUTE STATEMENT ds ON EXTERNAL DBPath AS USER usr PASSWORD psw INTO :RemoteDB;
      WHEN ANY DO BEGIN
        RemoteDB = NULL;                                    -- In case that connection cannot be established, it is not this node
      END
    END
    IF(RemoteDB = CurrentDB)THEN BEGIN                      -- Node found
      Rdb$Set_Context('USER_SESSION','REPL$CURRENTDBNO', DBNo);
      EXIT;
    END
  END
  Rdb$Set_Context('USER_SESSION','REPL$CURRENTDBNO', '-');  -- Node not found
END
^
SET TERM ;^
