SET TERM ^;
EXECUTE BLOCK
RETURNS(line VARCHAR(200))
AS
DECLARE Tbl VARCHAR(128);
BEGIN
  line = '-- Generated at '||LOCALTIMESTAMP;
  SUSPEND;
  -- Add Missing fields into existing tables
  FOR SELECT Table_Name FROM  LIB$CMP_Tables('d:\fbdata\kingspan_mes_prod.fdb', 'sysdba', 'masterkey')
  INTO Tbl DO BEGIN
    line = Tbl;
    SUSPEND;
  END 
END
^
SET TERM ;^
COMMIT;
