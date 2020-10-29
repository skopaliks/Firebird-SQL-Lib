/******************************************************************************
* Stored Procedure : LIB$CMP_Tables
*                                                                            
* Date    : 2017-09-13
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.7
* Purpose : Compare stored tables in current DB with remote one and returns
*           what is different
*                                                                               
* Revision History                                                           
* ================                                                           
* 2020-03-05 - S.Skopalik   Fixed field position calculation, exclude views from comparision
* 2020-07-22 - S.Skopalik   Added FieldType
* 2020-10-28 - S.Skopalik   Fixed field position calculation
******************************************************************************/
SET TERM ^;
^

CREATE OR ALTER PROCEDURE LIB$CMP_Tables(
  Target_DB       VARCHAR(500) NOT NULL,
  Target_User     VARCHAR(63),
  Target_Password VARCHAR(63),
  Target_Role     VARCHAR(63) DEFAULT NULL
)RETURNS(
  Table_Name        RDB$Relation_Name,
  Field_Name        RDB$Field_Name,
  Field_Pos         SMALLINT,
  Field_Pos_Target  SMALLINT,
  Field_null        SMALLINT,           -- Field Null Flag (RDB$NULL_FLAG)
  Field_null_Target SMALLINT,
  Field_Source      RDB$Field_Name,
  Field_Source_Target RDB$Field_Name,
  Field_Type        VARCHAR(127),  
  IsTableMissing    LIB$BooleanF,
  IsFieldMissing    LIB$BooleanF
)AS
DECLARE t_Rel   RDB$Relation_Name;
DECLARE t_Field RDB$Field_Name;
BEGIN
  FOR SELECT R.RDB$Relation_Name, RF.RDB$FIELD_NAME, 
    (SELECT COUNT(*) FROM Rdb$Relation_Fields RF2 WHERE RF2.rdb$Relation_Name = R.RDB$Relation_Name AND RF2.RDB$FIELD_POSITION <= RF.RDB$FIELD_POSITION), 
    COALESCE(RF.RDB$NULL_FLAG,0), RF.RDB$FIELD_SOURCE, FT.DataType
    FROM RDB$Relations R
    LEFT JOIN Rdb$Relation_Fields RF ON RF.rdb$Relation_Name = R.RDB$Relation_Name
    LEFT JOIN RDB$Fields F ON F.RDB$FIELD_NAME=RF.RDB$FIELD_SOURCE
    LEFT JOIN LIB$CMP_GetFieldDataType(RF.RDB$FIELD_SOURCE) FT ON 1=1
    WHERE R.RDB$RELATION_TYPE = 0 OR R.RDB$RELATION_TYPE IS NULL
    ORDER BY R.RDB$Relation_Name, RF.RDB$FIELD_POSITION
    INTO Table_Name, Field_Name, Field_Pos, Field_null, Field_Source, Field_Type DO BEGIN
      t_Rel = NULL;
      t_Field = NULL;
      Field_Pos_Target = NULL;
      EXECUTE STATEMENT (
        'SELECT R.RDB$Relation_Name, RF.RDB$FIELD_NAME, (SELECT COUNT(*) FROM Rdb$Relation_Fields RF2 WHERE RF2.rdb$Relation_Name = R.RDB$Relation_Name AND RF2.RDB$FIELD_POSITION <= RF.RDB$FIELD_POSITION)
         FROM RDB$Relations R
         LEFT JOIN Rdb$Relation_Fields RF ON RF.rdb$Relation_Name = R.RDB$Relation_Name AND RF.RDB$FIELD_NAME = :fn
         WHERE R.rdb$Relation_Name = :rn'
        )(rn := :Table_Name, fn := :Field_Name)
        ON EXTERNAL DATA SOURCE Target_DB
        AS USER Target_User
        PASSWORD Target_Password
        ROLE Target_Role
        INTO t_Rel, t_Field, Field_Pos_Target;
        IsTableMissing = IIF(t_Rel IS NULL, 1, 0);
        IsFieldMissing = IIF(t_Field IS NULL, 1, 0);
      SUSPEND;
  END
END
^

SET TERM ;^

