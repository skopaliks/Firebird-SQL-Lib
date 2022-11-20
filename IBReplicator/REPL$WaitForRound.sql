/******************************************************************************
* Stored Procedure : Repl$WaitForRound
*
* Date    : 2020-10-10
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.9
* Purpose : Wait till all replication command are finished from current node
*   Useful during metadata changes in replication cluster
*   In case that IBReplicator is not configured, returns immediatelly
*   
* Revision History
* ================
* 2022-11-20  SkopalikS    Fixed bug in non replicated commands condition
******************************************************************************/
SET TERM ^;
CREATE OR ALTER PROCEDURE Repl$WaitForRound(
  ScanTime INTEGER = 1000  -- Define time beween check, that repl$log was processed
) RETURNS (
  EntriesToProcess BIGINT, EntriesProcessed BIGINT,
  ElapsedTime INTEGER -- [ms]
  ) AS
DECLARE sqm BIGINT;
DECLARE cnt BIGINT;
DECLARE bcnt BIGINT;
DECLARE bDate TIMESTAMP;
BEGIN
  IF(NOT EXISTS(SELECT * FROM rdb$Relations WHERE rdb$Relation_Name = 'REPL$LOG'))THEN EXIT;
  bDate = GetExactTimestampUTC();
  IN AUTONOMOUS TRANSACTION DO BEGIN
    EXECUTE STATEMENT 'SELECT MAX(SeqNo), COUNT(*) FROM Repl$log ' INTO sqm, bcnt;
  END
  EntriesToProcess = bcnt;
  EntriesProcessed = 0;
  ElapsedTime = ((GetExactTimestampUTC()-bDate)*24*3600*1000);
  SUSPEND;
  WHILE(EntriesToProcess > 0)DO BEGIN
    Sleep(ScanTime);
    IN AUTONOMOUS TRANSACTION DO BEGIN
      EXECUTE STATEMENT 'SELECT MAX(SeqNo), COUNT(*) FROM Repl$log WHERE SeqNo<='||sqm INTO sqm, cnt;
    END
    EntriesToProcess = cnt;
    EntriesProcessed = bcnt - cnt;
    ElapsedTime = ((GetExactTimestampUTC()-bDate)*24*3600*1000);
    SUSPEND;
  END
END
^
SET TERM ;^
