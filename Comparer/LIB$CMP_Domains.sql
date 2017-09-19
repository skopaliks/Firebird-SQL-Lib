/******************************************************************************
* Stored Procedure : LIB$CMP_Domains
*                                                                            
* Date    : 2017-09-17
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.7
* Purpose : Compare domains
*                                                                               
* Revision History                                                           
* ================                                                           
*                                                                            
*                                                                            
******************************************************************************/
SET TERM ^;
CREATE OR ALTER PROCEDURE LIB$CMP_Domains(
  Target_DB       VARCHAR(500) NOT NULL,
  Targer_User     VARCHAR(63),
  Target_Password VARCHAR(63),
  Target_Role     VARCHAR(63) DEFAULT NULL
)RETURNS(
  Domain_Name            RDB$Field_Name,
  IsDifferent            LIB$BooleanF, 
  IsMissing              LIB$BooleanF  
)AS
DECLARE ds VARCHAR(500);
DECLARE blr_v_l BLOB; -- RDB$VALIDATION_BLR
DECLARE blr_v_r BLOB;
DECLARE blr_c_l BLOB; -- RDB$COMPUTED_BLR
DECLARE blr_c_r BLOB;
DECLARE blr_d_l BLOB; -- RDB$DEFAULT_VALUE
DECLARE blr_d_r BLOB;
DECLARE ft_l    TYPE OF COLUMN RDB$Fields.RDB$Field_Type;
DECLARE ft_r    TYPE OF COLUMN RDB$Fields.RDB$Field_Type;
BEGIN
  ds = 'SELECT RDB$VALIDATION_BLR, RDB$COMPUTED_BLR, RDB$DEFAULT_VALUE, RDB$Field_Type FROM RDB$Fields WHERE RDB$Field_Name = :fn';
  FOR SELECT RDB$Field_Name, RDB$VALIDATION_BLR, RDB$COMPUTED_BLR, RDB$DEFAULT_VALUE, RDB$Field_Type FROM RDB$Fields
    WHERE COALESCE(RDB$SYSTEM_FLAG, 0) = 0 AND RDB$Field_Name NOT LIKE 'RDB$_%'
    INTO :Domain_Name, :blr_v_l, :blr_c_l, :blr_d_l, :ft_l DO BEGIN
    IsDifferent = 0;
    IsMissing = 0;
    ft_l = NULL;
    EXECUTE STATEMENT (:ds)(fn := :Domain_Name)
        ON EXTERNAL DATA SOURCE Target_DB
        AS USER Targer_User
        PASSWORD Target_Password
        ROLE Target_Role
        INTO :blr_v_r, :blr_c_r, :blr_d_r, :ft_r;
    IF(ft_l IS NULL)THEN IsMissing = 1;
     ELSE BEGIN
      IF(blr_v_l IS DISTINCT FROM blr_v_r)THEN IsDifferent = 1;
      IF(blr_c_l IS DISTINCT FROM blr_c_r)THEN IsDifferent = 1;
      IF(blr_d_l IS DISTINCT FROM blr_d_r)THEN IsDifferent = 1;
      IF(ft_l IS DISTINCT FROM ft_r)THEN IsDifferent = 1;
    END
    SUSPEND;
  END
END
^
SET TERM ;^
