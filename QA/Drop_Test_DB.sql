-- Delete test user to avoid security hole

SET TERM ^;
-- do not fail if user exists
EXECUTE BLOCK AS
DECLARE VARIABLE s VARCHAR(1000);
BEGIN   
  s = 'DROP USER REPL_FB_Lib;';
  BEGIN
    EXECUTE STATEMENT s;
  WHEN ANY DO BEGIN END
  END  
END
^

SET TERM ;^
COMMIT;

DROP DATABASE;
