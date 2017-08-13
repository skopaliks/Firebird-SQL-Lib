/******************************************************************************
* 
* Date    : 2017-08-13
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.7
* Purpose : Ensure that sequence of triggers fireng is determinable
*  
* Revision History
* ================
*
******************************************************************************/
CREATE OR ALTER EXCEPTION LIB$TriggerPossitionCheck 'Triggers can be fired in random order';

SET TERM ^;

CREATE OR ALTER PROCEDURE LIB$CheckTriggersPossitions(
  RaiseException SMALLINT DEFAULT 0  -- Raise Exception if a conflict found
)RETURNS(
  Relation_Name TYPE OF COLUMN RDB$Triggers.RDB$Relation_Name,
  Pos           TYPE OF COLUMN RDB$Triggers.RDB$TRIGGER_SEQUENCE,
  Trigger_Type  VARCHAR(30),
  tg_names      VARCHAR(2000)
)
AS
DECLARE i INTEGER;
DECLARE ttp1 INTEGER;
DECLARE ttp2 INTEGER;
DECLARE ttp3 INTEGER;
DECLARE ttp4 INTEGER;
DECLARE cnt  INTEGER=0; -- Count of conflicts
BEGIN
  i = 0;
  WHILE(i<=10)DO BEGIN
    ttp2=-1; ttp3=-1; ttp4=-1;
    -- Before/After insert
    IF(i IN(0,3))THEN BEGIN
      Trigger_Type = 'BEFORE INSERT';
      ttp1 = 1;
      ttp2 = 17;
      ttp3 = 25;
      ttp4 = 113;
    END
    -- Before update
    IF(i IN(1,4))THEN BEGIN
      Trigger_Type = 'BEFORE UPDATE';
      ttp1 = 3;
      ttp2 = 17;
      ttp3 = 27;
      ttp4 = 113;
    END
    -- Before delete
    IF(i IN(2,5))THEN BEGIN
      Trigger_Type = 'BEFORE DELETE';
      ttp1 = 5;
      ttp2 = 25;
      ttp3 = 27;
      ttp4 = 113;
    END
    -- After INSERT/UPDATE/DELETE
    IF(i IN(3,4,5))THEN BEGIN
      Trigger_Type = 'AFTER'||SUBSTRING(Trigger_Type FROM 7);
      ttp1 = ttp1 + 1;
      ttp2 = ttp2 + 1;
      ttp3 = ttp3 + 1;
      ttp4 = ttp4 + 1;
    END
    -- On connect
    IF(i=6)THEN BEGIN
      Trigger_Type = 'ON CONNECT';
      ttp1 = 8192;
    END
    -- On disconnect
    IF(i=7)THEN BEGIN
      Trigger_Type = 'ON DISCONNECT';
      ttp1 = 8193;
    END
    -- On transaction start
    IF(i=8)THEN BEGIN
      Trigger_Type = 'ON TRANSACTION START';
      ttp1 = 8194;
    END
    -- On transaction commit
    IF(i=9)THEN BEGIN
      Trigger_Type = 'ON TRANSACTION COMMIT';
      ttp1 = 8195;
    END
    -- On transaction rollback
    IF(i=10)THEN BEGIN
      Trigger_Type = 'ON TRANSACTION ROLLBACK';
      ttp1 = 8196;
    END
    FOR SELECT RDB$Relation_Name, RDB$TRIGGER_SEQUENCE, LIST(TRIM(RDB$Trigger_Name)) FROM RDB$Triggers
      WHERE RDB$System_Flag=0 AND RDB$Trigger_Type IN(:ttp1, :ttp2, :ttp3, :ttp4)
      GROUP BY RDB$Relation_Name, RDB$TRIGGER_SEQUENCE
      HAVING COUNT(*)>1
      INTO :Relation_Name, :Pos, :tg_names DO BEGIN
      SUSPEND;
      cnt = cnt + 1;
    END
    i = i + 1;
  END
  IF(RaiseException>0 AND cnt>0)THEN
    EXCEPTION LIB$TriggerPossitionCheck 'There are '||cnt||' of trigger position conflicts';
END
^

SET TERM ;^

