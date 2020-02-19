SET TERM ^;
EXECUTE BLOCK
RETURNS(line VARCHAR(200))
AS
DECLARE db  VARCHAR(500);
DECLARE tbl VARCHAR(128);
DECLARE fld VARCHAR(128);
DECLARE fsd VARCHAR(200);
BEGIN
  db = RDB$GET_CONTEXT('USER_SESSION','DB_Target');
  line = '-- Generated at '||LOCALTIMESTAMP;
  SUSPEND;
  line = '-- Target DB:'||db;
  SUSPEND;
  -- Add Missing fields into existing tables
  FOR SELECT TRIM(Table_Name), TRIM(Field_Name), TRIM(Field_Source) FROM  LIB$CMP_Tables(:db, 'sysdba', 'masterkey')
  WHERE IsFieldMissing = 1 AND IsTableMissing = 0
  INTO tbl, fld, fsd DO BEGIN
    line = 'INSERT INTO Repl$DDL(SQL)SELECT ''ALTER TABLE '||tbl||' ADD '||fld||' '||fsd||''' FROM rdb$database';
    SUSPEND;
    line = '  WHERE NOT EXISTS(SELECT * FROM Rdb$Relation_Fields RF WHERE RF.rdb$Relation_Name = '''||tbl||''' AND RF.RDB$FIELD_NAME = '''||fld||''');'; 
    SUSPEND;
    line = 'COMMIT;';
    SUSPEND;
    line = 'SELECT * FROM Repl$WaitForRound(500); COMMIT;';
    SUSPEND;
    line = 'SELECT * FROM Repl$AddOrUpdateRelation('''||tbl||''',NULL); COMMIT;';
    SUSPEND;
    line = 'EXECUTE PROCEDURE MASA$UpdateBussinesObjects(UPPER('''||tbl''')); COMMIT;';
    SUSPEND;
  END 
END
^
SET TERM ;^
COMMIT;
