/******************************************************************************
* Stored Procedure : LIB$CMP_GetUserType
*                                                                            
* Date    : 2018-06-29
* Author  : Jaroslav Kejnar
* Server  : Firebird 2.5.8
* Purpose : Returns text (e.g. BEFORE INSERT) for given trigger type number
*                                                                               
* Revision History                                                           
* ================                                                           
* 2022-11-21  SkopalikS    Fixed bug in AFTER UPDATE OR DELETE                                                                           
*                                                                            
******************************************************************************/
SET TERM ^;

CREATE OR ALTER PROCEDURE LIB$CMP_GetTriggerType(
  RDB$TRIGGER_TYPE TYPE OF COLUMN RDB$TRIGGERS.RDB$TRIGGER_TYPE NOT NULL
)RETURNS(
  TriggerType VARCHAR(63)
)
AS
BEGIN
  TriggerType =
    TRIM(CASE RDB$TRIGGER_TYPE
      WHEN 1 THEN 'BEFORE INSERT'
      WHEN 2 THEN 'AFTER INSERT'
      WHEN 3 THEN 'BEFORE UPDATE'
      WHEN 4 THEN 'AFTER UPDATE'
      WHEN 5 THEN 'BEFORE DELETE'
      WHEN 6 THEN 'AFTER DELETE'
      WHEN 17 THEN 'BEFORE INSERT OR UPDATE'
      WHEN 18 THEN 'AFTER INSERT OR UPDATE'
      WHEN 25 THEN 'BEFORE INSERT OR DELETE'
      WHEN 26 THEN 'AFTER INSERT OR DELETE'
      WHEN 27 THEN 'BEFORE UPDATE OR DELETE'
      WHEN 28 THEN 'AFTER UPDATE OR DELETE'
      WHEN 113 THEN 'BEFORE INSERT OR UPDATE OR DELETE'
      WHEN 114 THEN 'AFTER UPDATE OR DELETE'
      WHEN 8192 THEN 'ON CONNECT'
      WHEN 8193 THEN 'ON DISCONNECT'
      WHEN 8194 THEN 'ON TRANSACTION START'
      WHEN 8195 THEN 'ON TRANSACTION COMMIT'
      WHEN 8196 THEN 'ON TRANSACTION ROLLBACK'
    END);
  IF(TriggerType IS NULL)THEN EXCEPTION LIB$CMP_Exception 'RDB$TRIGGER_TYPE('||RDB$TRIGGER_TYPE||') is unknow'; 
  SUSPEND;  
END
^

SET TERM ;^
