SET TERM ^;
EXECUTE BLOCK
RETURNS(line VARCHAR(200))
AS
DECLARE db    VARCHAR(500);
DECLARE tbl   VARCHAR(128);
DECLARE fld   VARCHAR(128);
DECLARE fsd   VARCHAR(200);
DECLARE ft    VARCHAR(200);
DECLARE fnull    SMALLINT;
DECLARE pos      INTEGER;
DECLARE Last_Tbl VARCHAR(128);
DECLARE UserName VARCHAR(64) = 'sysdba';
DECLARE UserPass VARCHAR(64) = 'masterkey';
BEGIN
  db = RDB$GET_CONTEXT('USER_SESSION','DB_Target');
  line = '-- Generated at '||LOCALTIMESTAMP;
  SUSPEND;
  line = '-- Target DB:'||db;
  SUSPEND;
  -- Add Missing fields into existing tables
  FOR SELECT TRIM(Table_Name), TRIM(Field_Name), TRIM(Field_Source), Field_Type, Field_Null FROM  LIB$CMP_Tables(:db, 'sysdba', 'masterkey')
  WHERE IsFieldMissing = 1 AND IsTableMissing = 0
  INTO tbl, fld, fsd, ft, fnull DO BEGIN
    line = '';
    SUSPEND;
    line = 'INSERT INTO Repl$DDL(SQL)SELECT ''ALTER TABLE '||tbl||' ADD '||fld||' '||ft||''' FROM rdb$database';
    SUSPEND;
    line = '  WHERE NOT EXISTS(SELECT * FROM Rdb$Relation_Fields RF WHERE RF.rdb$Relation_Name = '''||tbl||''' AND RF.RDB$FIELD_NAME = '''||fld||''');'; 
    SUSPEND;
    line = 'COMMIT;';
    SUSPEND;
    line = 'SELECT * FROM Repl$WaitForRound(500); COMMIT;';
    SUSPEND;
    line = 'SELECT * FROM Repl$AddOrUpdateRelation('''||tbl||''',NULL); COMMIT;';
    SUSPEND;
    IF(fnull>0)THEN BEGIN
      line = '-- Add code to set field to NOT NULL';
      SUSPEND;
      line = 'SELECT * FROM Repl$WaitForRound(500); COMMIT;';
      SUSPEND;
      line = 'EXECUTE PROCEDURE MASA$Set_Null_Flag('''||tbl||''', '''||fld||''', 1); COMMIT;';
      SUSPEND;
    END
    line = 'EXECUTE PROCEDURE MASA$UpdateBussinesObjects(UPPER('''||tbl||''')); COMMIT;';
    SUSPEND;
  END
  Last_Tbl = '';
  FOR SELECT TRIM(Table_Name), TRIM(Field_Name), TRIM(Field_Source), Field_Type, Field_Null FROM  LIB$CMP_Tables(:db, 'sysdba', 'masterkey')
  WHERE IsFieldMissing = 1 AND IsTableMissing = 1
  INTO tbl, fld, fsd, ft, fnull DO BEGIN
    line = '';
    IF(Last_Tbl = tbl)THEN line = ',';
    IF(Last_Tbl <> tbl)THEN BEGIN
      IF(Last_Tbl <> '')THEN BEGIN
        line = ')'' FROM RDB$Database WHERE NOT EXISTS(SELECT * FROM RDB$Relations WHERE RDB$Relation_Name = '''||Last_Tbl||''') ;';
        SUSPEND;
      END
      line = 'INSERT INTO Repl$DDL(SQL)SELECT ''CREATE TABLE '||tbl||'(';
      Last_Tbl = tbl;
    END
    line = line || fld || ' ' ||ft ||IIF(fnull=1, ' NOT NULL', '');
    SUSPEND;
  END
  IF(Last_Tbl <> '')THEN BEGIN
    line = ')'' FROM RDB$Database WHERE NOT EXISTS(SELECT * FROM RDB$Relations WHERE RDB$Relation_Name = '''||Last_Tbl||''') ;';
    SUSPEND;
  END
  -- Adjust NOT NULL flag
  FOR SELECT TRIM(Table_Name), TRIM(Field_Name), TRIM(Field_Source), Field_Null FROM  LIB$CMP_Tables(:db, :UserName, :UserPass)
    WHERE IsFieldMissing = 0 AND IsTableMissing = 0 AND Field_Null <> Field_null_Target
    INTO tbl, fld, fsd, fnull DO BEGIN
    line = 'EXECUTE PROCEDURE MASA$Set_Null_Flag('''||tbl||''', '''||fld||''', '||fNull||');';
    SUSPEND;
  END
  -- Update field position
  fsd = '';
  FOR SELECT TRIM(Table_Name), TRIM(Field_Name), field_pos FROM  LIB$CMP_Tables(:db, :UserName, :UserPass)
  WHERE field_pos <> field_pos_target
  ORDER BY Table_Name, field_pos
  INTO tbl, fld, pos DO BEGIN
    line = 'INSERT INTO Repl$DDL(SQL) VALUES(''ALTER TABLE '||tbl||' ALTER COLUMN '||fld||' POSITION '||pos||''');';
    if(fsd <> tbl) THEN SUSPEND;
    fsd = tbl;
  END
  line = 'COMMIT;';
  SUSPEND;   
END
^
SET TERM ;^
COMMIT;
