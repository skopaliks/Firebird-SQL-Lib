/******************************************************************************
* Stored Procedure : LIB$CMP_Procedures
*                                                                            
* Date    : 2017-09-13
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.7
* Purpose : Compare stored procedures in current DB with remote one and returns
*           what is different
*                                                                               
* Revision History                                                           
* ================                                                           
*                                                                            
*                                                                            
******************************************************************************/
SET TERM ^;

CREATE OR ALTER PROCEDURE LIB$CMP_Procedures(
  Target_DB       VARCHAR(500) NOT NULL,
  Targer_User     VARCHAR(63),
  Target_Password VARCHAR(63),
  Target_Role     VARCHAR(63) DEFAULT NULL
)RETURNS(
  Procedure_Name  RDB$Procedure_Name,
  IsDifferent     SMALLINT,
  IsMissing       SMALLINT
)AS
DECLARE ds VARCHAR(500);
DECLARE blr_l BLOB;
DECLARE blr_r BLOB;
DECLARE In_cnt_l INTEGER;
DECLARE Out_cnt_l INTEGER;
DECLARE In_cnt_r INTEGER;
DECLARE Out_cnt_r INTEGER;
BEGIN
  ds = 'SELECT
          RDB$Procedure_BLR,
          (SELECT COUNT(*) FROM RDB$PROCEDURE_PARAMETERS WHERE RDB$Procedure_Name=RDB$Procedures.RDB$Procedure_Name AND Rdb$Parameter_Type=0),
          (SELECT COUNT(*) FROM RDB$PROCEDURE_PARAMETERS WHERE RDB$Procedure_Name=RDB$Procedures.RDB$Procedure_Name AND Rdb$Parameter_Type=1)
          FROM RDB$Procedures WHERE RDB$Procedure_Name=:psn';
  FOR
    SELECT
      RDB$Procedure_Name,
      RDB$Procedure_BLR,
      (SELECT COUNT(*) FROM RDB$PROCEDURE_PARAMETERS WHERE RDB$Procedure_Name=RDB$Procedures.RDB$Procedure_Name AND Rdb$Parameter_Type=0),
      (SELECT COUNT(*) FROM RDB$PROCEDURE_PARAMETERS WHERE RDB$Procedure_Name=RDB$Procedures.RDB$Procedure_Name AND Rdb$Parameter_Type=1)
    FROM RDB$Procedures
    INTO :Procedure_Name, :blr_l, :In_cnt_l, :Out_cnt_l DO BEGIN
    blr_r = NULL;
    IsMissing = 0;
    IsDifferent = 0;
    EXECUTE STATEMENT (:ds)(psn := :Procedure_Name)
        ON EXTERNAL DATA SOURCE Target_DB
        AS USER Targer_User
        PASSWORD Target_Password
        INTO :blr_r, :In_cnt_r, :Out_cnt_r;
    IF(blr_r IS NULL)THEN IsMissing = 1;
     ELSE BEGIN
      IF(blr_r <> blr_l)THEN IsDifferent = 1;
      IF(In_cnt_l <> In_cnt_r OR Out_cnt_l <> Out_cnt_r)THEN IsDifferent = 1;
    END
    IF(IsMissing = 0 AND IsDifferent = 0)THEN BEGIN
      -- BLR is same, but parameters can be different, now time to check it
    END
    SUSPEND;
  END
END
^

SET TERM ;^
