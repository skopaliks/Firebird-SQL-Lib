CREATE TABLE CMP_TEST(a INTEGER);
COMMIT;
SET TERM ^;

EXECUTE BLOCK 
AS
DECLARE CRLF  LIB$CRLF;
DECLARE v_ddl BLOB;
DECLARE t_header VARCHAR(1000);
DECLARE t_source VARCHAR(2000);
DECLARE t_dsc VARCHAR(1000);
BEGIN
  t_header = 'CREATE OR ALTER TRIGGER TEST_TRIGGER_BIU FOR CMP_TEST BEFORE INSERT OR UPDATE POSITION 33';
  t_source = 'AS' || CRLF || 'BEGIN' || CRLF || '  --some comment for test in code' || CRLF
            || '  INSERT INTO CMP_TEST VALUES(3);' || CRLF || 'END';
  t_dsc = 'COMMENT ON TRIGGER TEST_TRIGGER_BIU IS ''test trigger comment''';
  EXECUTE STATEMENT t_header || CRLF || t_source;
  EXECUTE STATEMENT t_dsc;
  IF(t_header <> (SELECT CAST(ddl AS VARCHAR(1000)) FROM LIB$CMP_ExtractTrigger('TEST_TRIGGER_BIU', 0) WHERE isHeader = 1)) THEN
    EXCEPTION LIB$CMP_EXCEPTION 'Extracted trigger header is different';
  IF(t_source <> (SELECT CAST(ddl AS VARCHAR(2000)) FROM LIB$CMP_ExtractTrigger('TEST_TRIGGER_BIU', 0) WHERE isSource = 1)) THEN
    EXCEPTION LIB$CMP_EXCEPTION 'Extracted trigger source is different';
  IF(t_dsc <> (SELECT CAST(ddl AS VARCHAR(1000)) FROM LIB$CMP_ExtractTrigger('TEST_TRIGGER_BIU', 0) WHERE isComment = 1)) THEN
    EXCEPTION LIB$CMP_EXCEPTION 'Extracted trigger comment is different';
  -- Test Transaction Rollback troggers
  IF((SELECT CAST(COALESCE(ddl, 'NULL') AS VARCHAR(1000)) FROM LIB$CMP_ExtractTrigger('LIB$TR_MONITOR_ROLLBACK', 0) WHERE isBody = 1) NOT LIKE '%IN AUTONOMOUS TRANSACTION DO BEGIN%' ) THEN
    EXCEPTION LIB$CMP_EXCEPTION 'Extraction of roll back trigger failed';
END
^
SET TERM ;^
ROLLBACK;

DROP TABLE CMP_TEST;
COMMIT;
