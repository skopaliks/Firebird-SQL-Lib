SET TERM ^;
EXECUTE BLOCK
RETURNS(line VARCHAR(500))
AS

-- https://www.tabsoverspaces.com/232347-tokenize-string-in-sql-firebird-syntax
declare procedure Tokenize(input LIB$LargeText, token char(1))
returns (result varchar(500))
as
declare newpos int;
declare oldpos int;
begin
  oldpos = 1;
  newpos = 1;
  while (1 = 1) do
  begin
    newpos = position(token, input, oldpos);
    if (newpos > 0) then
    begin
      result = substring(input from oldpos for newpos - oldpos);
      suspend;
      oldpos = newpos + 1;
    end
    else if (oldpos - 1 < char_length(input)) then
    begin
      result = substring(input from oldpos);
      suspend;
      break;
    end
    else
    begin
      break;
    end
  end
end


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
  FOR SELECT TRIM(Table_Name), TRIM(Field_Name), TRIM(Field_Source), Field_Type, Field_Null FROM  LIB$CMP_Tables(:db, :UserName, :UserPass)
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
  FOR SELECT TRIM(Table_Name), TRIM(Field_Name), TRIM(Field_Source), Field_Type, Field_Null FROM  LIB$CMP_Tables(:db, :UserName, :UserPass)
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
  FOR SELECT Trigger_Name, DDL, Master_Source, Target_Source FROM LIB$CMP_Triggers(:db, :UserName, :UserPass, NULL, '%_GN_%') AS CURSOR tc DO BEGIN
    -- Target trigger source code
    line = '-- Trigger ' || TRIM(tc.Trigger_Name) || ' target code:';
    SUSPEND;
    FOR SELECT '--'||result FROM Tokenize(tc.Target_Source, ASCII_CHAR(10)) INTO line DO BEGIN
      line = TRIM(ASCII_CHAR(13) FROM line);
      SUSPEND;
    END
    line = 'INSERT INTO Repl$DDL(SQL) VALUES(';
    SUSPEND;
    FOR SELECT REPLACE(result,'''','''''') FROM Tokenize(tc.DDL, ASCII_CHAR(10)) INTO line DO BEGIN
      line = ''''||TRIM(ASCII_CHAR(13) FROM line)||'''||ASCII_CHAR(10)||';
      SUSPEND;
    END
    line = ''''');';
    SUSPEND;
  END
  line = 'COMMIT;';
  SUSPEND;   
END
^
SET TERM ;^
COMMIT;
