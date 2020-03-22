/******************************************************************************
* Stored Procedure : LIB$CMP_GetFieldDataType
*                                                                            
* Date    : 2017-07-13
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.7
* Purpose : Returns data type definition (for table or stored procedure) from field source name
*           
*                                                                               
* Revision History                                                           
* ================                                                           
* 2017-07-20 - S.Skopalik: Fixed returning DefaultExpresion                                                                           
* 2017-09-17 - S.Skopalik: Added CheckExpresion
* 2020-03-22 - S.Skopalik: Added charcter set into DataType definition
******************************************************************************/
SET TERM ^;

CREATE OR ALTER PROCEDURE LIB$CMP_GetFieldDataType(
  Field_Source      RDB$Field_Name NOT NULL,
  Return_Basic_Type LIB$BooleanF DEFAULT 0
)RETURNS(
  DataType VARCHAR(127),
  DefaultExpresion TYPE OF COLUMN RDB$Fields.RDB$DEFAULT_Source,
  CheckExpresion   TYPE OF COLUMN RDB$Fields.RDB$VALIDATION_SOURCE
)AS
DECLARE ft SMALLINT;
DECLARE st SMALLINT;         -- SUB_TYPE
DECLARE sl SMALLINT;
DECLARE cl     SMALLINT;     -- Char length
DECLARE chrset SMALLINT;     -- Character Set id
DECLARE fpre   SMALLINT;     -- Number of digit for DECIMAL and NUMERIC
DECLARE fscl   SMALLINT;     -- Field scale for DECIMAL and NUMERIC
BEGIN
  -- Identify system domain
  IF(NOT Field_Source LIKE 'RDB$_%' AND Return_Basic_Type=0)THEN BEGIN
    DataType = Field_Source;
    SUSPEND;
    EXIT;
  END
  SELECT 
    RDB$FIELD_TYPE, RDB$FIELD_SUB_TYPE, RDB$SEGMENT_LENGTH, RDB$CHARACTER_LENGTH, RDB$FIELD_PRECISION, ABS(RDB$FIELD_SCALE),
    RDB$DEFAULT_Source, RDB$VALIDATION_SOURCE, RDB$CHARACTER_SET_ID
    FROM RDB$Fields WHERE RDB$Field_Name = :Field_Source
    INTO :ft, :st, :sl, :cl, :fpre, :fscl, :DefaultExpresion, :CheckExpresion, :chrset;
  DataType =
    -- Warn !!! CASE returned CHAR(xx)
    TRIM(CASE ft
      WHEN 7 THEN 'SMALLINT'
      WHEN 8 THEN 'INTEGER'
      WHEN 10 THEN 'FLOAT'
      WHEN 12 THEN 'DATE'
      WHEN 13 THEN 'TIME'
      WHEN 14 THEN 'CHAR'
      WHEN 16 THEN 'BIGINT'
      WHEN 27 THEN 'DOUBLE PRECISION'
      WHEN 35 THEN 'TIMESTAMP'
      WHEN 37 THEN 'VARCHAR'
      WHEN 261 THEN 'BLOB'
     END);
  IF(DataType IS NULL)THEN EXCEPTION LIB$CMP_Exception Field_Source || ' Is unknow data type';
  IF(ft IN(7,8,16))THEN BEGIN
    IF(st = 1)THEN DataType = 'NUMERIC(' || fpre || ',' || fscl || ')';
    IF(st = 2)THEN DataType = 'DECIMAL(' || fpre || ',' || fscl || ')';
  END
  IF(ft IN(14,37)) THEN BEGIN  -- CHAR and VARCHAR
    IF(ft=14 AND st=3)THEN
      DataType = Field_Source; -- Not ducumented System data types like RDB$FIELD_NAME
     ELSE 
      DataType = DataType || '('||cl||')';
    IF(chrset IS NOT NULL)THEN BEGIN
      DataType = DataType ||' CHARACTER SET '||(SELECT RDB$CHARACTER_SET_NAME FROM RDB$CHARACTER_Sets WHERE RDB$CHARACTER_SET_ID = :chrset);
    END
  END
  IF(ft = 261) THEN DataType = DataType || ' SUB_TYPE ' || st || ' SEGMENT SIZE ' || sl;
  SUSPEND;
END
^
SET TERM ;^

COMMENT ON PROCEDURE LIB$CMP_GetFieldDataType IS 'Returns data type definition (for table or stored procedure) from field source name';
