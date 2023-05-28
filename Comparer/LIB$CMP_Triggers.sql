/******************************************************************************
* Stored Procedure : LIB$CMP_Triggers
*                                                                            
* Date    : 2023-04-10
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.7
* Purpose : Compare triggers in current DB with target one and returns
*           what is different
*                                                                               
* Revision History                                                           
* ================                                                           
* 2023-05-14 Skopalik S    Do not skip static replication triggers                                                                           
******************************************************************************/
SET TERM ^;

CREATE OR ALTER PROCEDURE LIB$CMP_Triggers(
  Target_DB       VARCHAR(500) NOT NULL,
  Target_User     VARCHAR(63),
  Target_Password VARCHAR(63),
  Target_Role     VARCHAR(63) DEFAULT NULL,
  Skip_Triggers   VARCHAR(200) DEFAULT ''       -- Like condition for triggers that have to be skipped during comprision
)RETURNS(
  Trigger_Name      CHAR(127),
  DDL               LIB$LargeText,
  Master_Source     LIB$LargeText,
  Target_Source     LIB$LargeText
)
AS
DECLARE t_type BIGINT;
DECLARE t_BLR BLOB;
BEGIN
  FOR SELECT rdb$Trigger_Name, rdb$Trigger_Type, rdb$Trigger_BLR, rdb$Trigger_Source
    FROM rdb$Triggers
    WHERE
      (rdb$System_Flag IS NULL OR rdb$System_Flag = 0)
      -- Exclude replicator triggers on tables. Format is REPL$<ReplNo>_<TargetDbNo>_<RelationNo>
      AND rdb$Trigger_Name NOT SIMILAR TO 'REPL$[[:DIGIT:]]+_[[:DIGIT:]]+_[[:DIGIT:]]+[[:SPACE:]]*'
      AND rdb$Trigger_Name NOT LIKE :Skip_Triggers
    ORDER BY 1
    AS CURSOR Lt DO BEGIN
    t_type = NULL;
    EXECUTE STATEMENT (
        'SELECT rdb$Trigger_Type, rdb$Trigger_BLR, rdb$Trigger_Source
         FROM rdb$Triggers
         WHERE rdb$Trigger_Name = :tn'
        )(tn := lt.rdb$Trigger_Name)
        ON EXTERNAL DATA SOURCE Target_DB
        AS USER Target_User
        PASSWORD Target_Password
        ROLE Target_Role
        INTO t_type, t_BLR, Target_Source;
    Target_Source = REPLACE(Target_Source, ASCII_CHAR(13), '');
    Master_Source = REPLACE(Lt.rdb$Trigger_Source, ASCII_CHAR(13), '');
    IF(t_type IS DISTINCT FROM Lt.rdb$Trigger_Type
      OR ( t_BLR IS DISTINCT FROM Lt.rdb$Trigger_BLR AND Target_Source IS DISTINCT FROM Master_Source) )THEN BEGIN
      Trigger_Name = lt.rdb$Trigger_Name;
      FOR SELECT DDL FROM LIB$CMP_ExtractTrigger(Lt.rdb$Trigger_Name, 0)
        WHERE IsBody = 1 OR IsComment = 1
        AS CURSOR Et DO BEGIN
        DDL = Et.DDL;
        SUSPEND;
      END
    END
  END
END
^

SET TERM ;^

