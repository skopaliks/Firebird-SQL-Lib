-- Test Time zone domain

CREATE TABLE DT(
  A LIB$Time_Zone
);
COMMIT;

INSERT INTO DT VALUES(NULL);              -- Test NULL
INSERT INTO DT VALUES('Europe/Prague');   -- Test IANA time zone
INSERT INTO DT VALUES('+03:00');          -- Test positive offset
INSERT INTO DT VALUES('-03:00');          -- Test negative offset

SET TERM ^;
EXECUTE BLOCK
AS
BEGIN
  BEGIN
    INSERT INTO DT VALUES('');
    EXCEPTION LIB$QA_Fail 'Emty string is not allowed';
  WHEN ANY DO BEGIN END
  END
  BEGIN
    INSERT INTO DT VALUES('Atlantida/Ocean');
    EXCEPTION LIB$QA_Fail 'Non existing time zone is not allwed';
  WHEN ANY DO BEGIN END
  END
  BEGIN
    INSERT INTO DT VALUES('10:00');
    EXCEPTION LIB$QA_Fail '+ or minus signum is necessary';
  WHEN ANY DO BEGIN END
  END
END
^
SET TERM ;^
COMMIT;
