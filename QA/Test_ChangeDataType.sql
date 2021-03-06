CREATE TABLE CDT(
   id INTEGER
);

SELECT * FROM LIB$DDL_ChangeDataType('CDT', 'ID', 'SMALLINT', 0);

SELECT * FROM LIB$DDL_ChangeDataType('CDT', 'ID', 'SMALLINT', 1);

SHOW TABLE CDT;
COMMIT;

RECREATE TABLE CDT(
   id INTEGER
);


SET TERM ^;
CREATE PROCEDURE CDT_P AS
BEGIN
  IF(EXISTS(SELECT SUM(id) FROM CDT))THEN BEGIN
  END
END
^
SET TERM ;^
COMMIT;

SELECT * FROM LIB$DDL_ChangeDataType('CDT', 'ID', 'SMALLINT', 0, 1);

SELECT * FROM LIB$DDL_ChangeDataType('CDT', 'ID', 'SMALLINT', 1, 1);
COMMIT;

SHOW TABLE CDT;
