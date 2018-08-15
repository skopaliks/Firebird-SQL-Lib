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
* 2018-06-27    Jaroslav Kejnar - procedure parameters comparation implemented, added procedures with flag NotExistsInCurrentDB from remoted DB which are missing in current DB
*                                                                            
******************************************************************************/
SET TERM ^;

CREATE OR ALTER PROCEDURE LIB$CMP_Procedures(
  Target_DB       VARCHAR(500) NOT NULL,
  Target_User     VARCHAR(63),
  Target_Password VARCHAR(63),
  Target_Role     VARCHAR(63) DEFAULT NULL
)RETURNS(
  Procedure_Name         RDB$Procedure_Name,
  IsDifferent            LIB$BooleanF,  -- returns 1 if declaration or body are different
  IsDifferentDelaration  LIB$BooleanF,  -- returns 1 if declaration is different
  IsMissing              LIB$BooleanF,
  NotExistsInCurrentDB   LIB$BooleanF,
  Procedure_BLR_L        BLOB,
  Procedure_BLR_R        BLOB,
  Procedure_Source_L     BLOB,
  Procedure_Source_R     BLOB
)
-- Work In Progress
AS
DECLARE ds VARCHAR(500);
DECLARE ps VARCHAR(1000);
DECLARE blr_l BLOB;
DECLARE blr_r BLOB;
DECLARE source_l BLOB CHARACTER SET UTF8;
DECLARE source_r BLOB CHARACTER SET UTF8;
DECLARE In_cnt_l INTEGER;
DECLARE Out_cnt_l INTEGER;
DECLARE In_cnt_r INTEGER;
DECLARE Out_cnt_r INTEGER;
DECLARE parameter_name CHAR(31);
DECLARE p_type SMALLINT;
DECLARE p_number SMALLINT;
DECLARE p_source CHAR(31);
DECLARE p_description BLOB CHARACTER SET UTF8;
DECLARE p_flag SMALLINT;
DECLARE p_default_value BLOB;
DECLARE p_default_source BLOB;
DECLARE p_collation_id SMALLINT;
DECLARE p_null_flag SMALLINT;
DECLARE p_mechanism SMALLINT;
DECLARE p_field_name CHAR(31);
DECLARE p_rel_name CHAR(31);
BEGIN
  ds = 'SELECT
          RDB$Procedure_BLR,
          TRIM(RDB$Procedure_Source),
          (SELECT COUNT(*) FROM RDB$PROCEDURE_PARAMETERS WHERE RDB$Procedure_Name=RDB$Procedures.RDB$Procedure_Name AND Rdb$Parameter_Type=0),
          (SELECT COUNT(*) FROM RDB$PROCEDURE_PARAMETERS WHERE RDB$Procedure_Name=RDB$Procedures.RDB$Procedure_Name AND Rdb$Parameter_Type=1)
          FROM RDB$Procedures WHERE RDB$Procedure_Name=:psn';
  NotExistsInCurrentDB = 0;
  FOR
    SELECT
      RDB$Procedure_Name,
      RDB$Procedure_BLR,
      TRIM(RDB$Procedure_Source),
      (SELECT COUNT(*) FROM RDB$PROCEDURE_PARAMETERS WHERE RDB$Procedure_Name=RDB$Procedures.RDB$Procedure_Name AND Rdb$Parameter_Type=0),
      (SELECT COUNT(*) FROM RDB$PROCEDURE_PARAMETERS WHERE RDB$Procedure_Name=RDB$Procedures.RDB$Procedure_Name AND Rdb$Parameter_Type=1)
    FROM RDB$Procedures
    INTO :Procedure_Name, :blr_l, :source_l, :In_cnt_l, :Out_cnt_l DO BEGIN
    blr_r = NULL;
    source_r = NULL;
    IsMissing = 0;
    IsDifferent = 0;
    IsDifferentDelaration = 0;
    EXECUTE STATEMENT (:ds)(psn := :Procedure_Name)
        ON EXTERNAL DATA SOURCE Target_DB
        AS USER Target_User
        PASSWORD Target_Password
        ROLE Target_Role
        INTO :blr_r, :source_r, :In_cnt_r, :Out_cnt_r;
    IF(blr_r IS NULL)THEN IsMissing = 1;
     ELSE BEGIN
      IF(blr_r <> blr_l)THEN BEGIN
        isDifferent = 1;
      -- compare sources with replaced different line breaks and whitespaces, becouse BLR and sources can be inserted with different line end or encoding.
        /*IF(REPLACE(REPLACE(:source_l, ASCII_CHAR(13) || ASCII_CHAR(10), ASCII_CHAR(13)), ASCII_CHAR(10), ASCII_CHAR(13))
            <>
            REPLACE(REPLACE(:source_r, ASCII_CHAR(13) || ASCII_CHAR(10), ASCII_CHAR(13)), ASCII_CHAR(10), ASCII_CHAR(13)))
            THEN isDifferent = 1;     */
      END
      IF(In_cnt_l <> In_cnt_r OR Out_cnt_l <> Out_cnt_r)THEN BEGIN
        IsDifferent = 1;
        IsDifferentDelaration = 1;
      END
    END
    IF(IsMissing = 0 AND IsDifferent = 0)THEN BEGIN
      -- BLR and source is same, but parameters can be different, now time to check it
      ps = 'SELECT RDB$Parameter_Type, RDB$Parameter_Number, RDB$Field_Source, RDB$Description, RDB$System_Flag, RDB$Default_Value, RDB$Default_Source, RDB$Collation_Id, RDB$Null_Flag, RDB$Parameter_Mechanism, RDB$Field_Name, RDB$Relation_Name
        FROM RDB$Procedure_Parameters WHERE RDB$Procedure_Name = ''' || :Procedure_Name || '''';
      FOR SELECT RDB$Parameter_Name
        FROM RDB$Procedure_Parameters
        WHERE RDB$Procedure_Name = :Procedure_Name
        ORDER BY RDB$Parameter_Type, RDB$Parameter_Number
        INTO :parameter_name
        DO BEGIN
            IF(:IsDifferent = 1) THEN BREAK;
            EXECUTE STATEMENT (:ps || ' AND RDB$Parameter_Name = ''' || :parameter_name || '''')
                ON EXTERNAL DATA SOURCE Target_DB
                    AS USER Target_User
                    PASSWORD Target_Password
                    ROLE Target_Role
                INTO :p_type, :p_number, :p_source, :p_description, :p_flag, :p_default_value, :p_default_source, :p_collation_id, :p_null_flag, :p_mechanism, :p_field_name, :p_rel_name;

            IF(
                :p_type <> (SELECT RDB$Parameter_Type FROM RDB$Procedure_Parameters WHERE RDB$Parameter_Name = :parameter_name AND RDB$Procedure_Name = :Procedure_Name) OR
                :p_number <> (SELECT RDB$Parameter_Number FROM RDB$Procedure_Parameters WHERE RDB$Parameter_Name = :parameter_name AND RDB$Procedure_Name = :Procedure_Name) OR
                IIF(:p_source STARTS WITH 'RDB$', NULL, :p_source) <> (SELECT RDB$Field_Source FROM RDB$Procedure_Parameters WHERE RDB$Parameter_Name = :parameter_name AND RDB$Procedure_Name = :Procedure_Name AND RDB$Field_Source NOT STARTS WITH 'RDB$') OR --without automatically generated Domains e.g. RDB$123
                :p_flag <> (SELECT RDB$System_Flag FROM RDB$Procedure_Parameters WHERE RDB$Parameter_Name = :parameter_name AND RDB$Procedure_Name = :Procedure_Name) OR
                :p_collation_id <> (SELECT RDB$Collation_Id FROM RDB$Procedure_Parameters WHERE RDB$Parameter_Name = :parameter_name AND RDB$Procedure_Name = :Procedure_Name) OR
                :p_null_flag <> (SELECT RDB$Null_Flag FROM RDB$Procedure_Parameters WHERE RDB$Parameter_Name = :parameter_name AND RDB$Procedure_Name = :Procedure_Name) OR
                :p_mechanism <> (SELECT RDB$Parameter_Mechanism FROM RDB$Procedure_Parameters WHERE RDB$Parameter_Name = :parameter_name AND RDB$Procedure_Name = :Procedure_Name) OR
                :p_field_name <> (SELECT RDB$Field_Name FROM RDB$Procedure_Parameters WHERE RDB$Parameter_Name = :parameter_name AND RDB$Procedure_Name = :Procedure_Name) OR
                :p_rel_name <> (SELECT RDB$Relation_Name FROM RDB$Procedure_Parameters WHERE RDB$Parameter_Name = :parameter_name AND RDB$Procedure_Name = :Procedure_Name) OR
                (SELECT REPLACE(REPLACE(TRIM(:p_description), ASCII_CHAR(13) || ASCII_CHAR(10), ASCII_CHAR(13)), ASCII_CHAR(10), ASCII_CHAR(13)) FROM RDB$Database)
                                <>
                (SELECT REPLACE(REPLACE(TRIM(RDB$Description), ASCII_CHAR(13) || ASCII_CHAR(10), ASCII_CHAR(13)), ASCII_CHAR(10), ASCII_CHAR(13)) FROM RDB$Procedure_Parameters WHERE RDB$Parameter_Name = :parameter_name AND RDB$Procedure_Name = :Procedure_Name)
            )
            THEN BEGIN
              IsDifferent = 1;
              IsDifferentDelaration = 1;
              BREAK;
            END
        END
    END
    Procedure_BLR_L = :blr_l;
    Procedure_BLR_R = :blr_r;
    Procedure_Source_L = :source_l;
    Procedure_Source_R = :source_r;
    SUSPEND;
  END
  --potentional procedures to drop
  IsMissing = 0;
  IsDifferent = 0;
  IsDifferentDelaration = 0;
  blr_l = NULL;
  source_l = NULL;
  Procedure_BLR_L = NULL;
  Procedure_Source_L = NULL;
  ds = 'SELECT
    RDB$Procedure_Name,
    RDB$Procedure_BLR,
    TRIM(RDB$Procedure_Source)
    FROM RDB$Procedures';
  FOR EXECUTE STATEMENT (:ds)
   ON EXTERNAL DATA SOURCE Target_DB
    AS USER Target_User
    PASSWORD Target_Password
    ROLE Target_Role
   INTO :Procedure_Name, :blr_r, :source_r
  DO BEGIN
    NotExistsInCurrentDB = 0;
    IF(NOT EXISTS (SELECT * FROM RDB$Procedures WHERE RDB$Procedure_Name = :Procedure_Name)) THEN BEGIN
        NotExistsInCurrentDB = 1;
        Procedure_BLR_R = :blr_r;
        Procedure_Source_R = :source_r;
        SUSPEND;
    END
  END

END
^

SET TERM ;^
