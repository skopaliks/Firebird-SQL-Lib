/******************************************************************************
* Selectable Stored Procedure : LIB$DDL_Get_FK_Info
*
* Date    : 2017-11-19
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.7
* Purpose : For given foreign key field returns appropriate primary key field 
*
* Revision History
* ================
******************************************************************************/
SET TERM ^;

CREATE OR ALTER PROCEDURE LIB$DDL_Get_FK_Info(Relation RDB$Relation_Name NOT NULL, Field RDB$Field_Name NOT NULL)
RETURNS(
  FK_Index_Name     RDB$INDEX_Name,
  FK_Index_Position RDB$FIELD_POSITION,
  PK_Relation_Name  RDB$Relation_Name,
  PK_Field_Name     RDB$Field_Name,
  PK_Index_Name     RDB$INDEX_Name
)
AS
BEGIN
  FOR SELECT I.Rdb$Index_Name, ISG.RDB$FIELD_POSITION, MC.RDB$Relation_Name, ISG_PK.RDB$Field_Name, MC.RDB$Index_Name
    FROM RDB$INDICES I
    JOIN RDB$RELATION_CONSTRAINTS C ON C.rdb$index_name=I.rdb$index_name
    JOIN RDB$REF_CONSTRAINTS RC ON RC.RDB$CONSTRAINT_NAME = C.RDB$Constraint_Name
    JOIN RDB$RELATION_CONSTRAINTS MC ON MC.RDB$CONSTRAINT_NAME = RC.rdb$const_name_uq
    JOIN RDB$Index_Segments ISG ON ISG.RDB$Index_Name = I.RDB$Index_Name
    JOIN RDB$Index_Segments ISG_PK ON ISG_PK.RDB$Index_Name = MC.RDB$Index_Name AND ISG_PK.RDB$FIELD_POSITION = ISG.RDB$FIELD_POSITION
    WHERE
      C.RDB$CONSTRAINT_TYPE='FOREIGN KEY' AND
      I.RDB$RELATION_NAME = :Relation AND ISG.RDB$Field_Name = :Field
    INTO :FK_Index_Name, :FK_Index_Position, :PK_Relation_Name, :PK_Field_Name, :PK_Index_Name DO BEGIN
    SUSPEND;
  END
END
^

SET TERM ;^

