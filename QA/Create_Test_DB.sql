-- Install all necesary DB object

-- Firebird UDF
INPUT c:/fb/udf/fbudf.sql;

-- IBReplicator config
INPUT c:\IBReplicator\config.sql;
SET TERM ;^

-- MasaUDFL: Sorry for that
INPUT ..\masa\sql\masaudf\masaudf.sql;


INPUT IncludeAll.sql;

COMMIT;

SET TERM ^;
-- do not fail if user exists
EXECUTE BLOCK AS
DECLARE VARIABLE s VARCHAR(1000);
BEGIN   
  s = 'CREATE USER REPL_FB_Lib PASSWORD ''test'';';
  BEGIN
    EXECUTE STATEMENT s;
  WHEN ANY DO BEGIN END
  END  
END
^

SET TERM ;^
COMMIT;

GRANT RDB$ADMIN TO REPL_FB_Lib;
COMMIT;

INPUT QA/Test_Repl$DDL.sql;
