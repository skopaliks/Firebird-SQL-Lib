SET TERM ^;

EXECUTE BLOCK 
AS
DECLARE v_alterscript BLOB;
DECLARE v_ddl BLOB;
BEGIN
  IF((SELECT COUNT(*) FROM Lib$Cmp_ExtractProcedure('LIB$CMP_PRIVILEGES', 0) WHERE isBody = 1) = 0) THEN
    EXCEPTION LIB$CMP_Exception 'Not extracted body of the procedure.';
  IF((SELECT COUNT(*) FROM Lib$Cmp_ExtractProcedure('LIB$CMP_PRIVILEGES', 0) WHERE isBody = 1) > 1) THEN
    EXCEPTION LIB$CMP_Exception 'Multiple extracting body of the procedure.';
  IF((SELECT COUNT(*) FROM Lib$Cmp_ExtractProcedure('LIB$CMP_PRIVILEGES', 0) WHERE isComment = 1) = 0) THEN
    EXCEPTION LIB$CMP_Exception 'Not extracted expected comments.';
  IF((SELECT COUNT(*) FROM Lib$Cmp_ExtractProcedure('LIB$CMP_PRIVILEGES', 0) WHERE isComment = 1 AND DDL STARTS WITH 'COMMENT ON PROCEDURE LIB$CMP_PRIVILEGES') = 0) THEN
    EXCEPTION LIB$CMP_Exception 'Not extracted procedure comment.';
  IF((SELECT COUNT(*) FROM Lib$Cmp_ExtractProcedure('LIB$CMP_PRIVILEGES', 0) WHERE isComment = 1 AND DDL STARTS WITH 'COMMENT ON PARAMETER LIB$CMP_PRIVILEGES') = 0) THEN
    EXCEPTION LIB$CMP_Exception 'Not extracted parameter comment.';
  IF((SELECT COUNT(*) FROM Lib$Cmp_ExtractProcedure('LIB$CMP_PRIVILEGES', 0) WHERE isGrant = 1) = 0) THEN
    EXCEPTION LIB$CMP_Exception 'Not extracted expected grant statements.';
  IF((SELECT COUNT(*) FROM Lib$Cmp_ExtractProcedure('LIB$CMP_PRIVILEGES', 0) WHERE isGrant = 1) <>
     (SELECT COUNT(*) FROM Lib$Cmp_ExtractProcedure('LIB$CMP_PRIVILEGES', 0) WHERE isRevoke = 1)
  ) THEN
    EXCEPTION LIB$CMP_Exception 'Not extracted expected revoke statements.';

  -- execute ddls
  EXECUTE STATEMENT (SELECT ddl FROM Lib$Cmp_ExtractProcedure('LIB$CMP_PRIVILEGES', 0) WHERE isBody = 1);

  FOR
    SELECT ddl
     FROM Lib$Cmp_ExtractProcedure('LIB$CMP_PRIVILEGES', 0)
     WHERE isGrant = 1 OR isComment = 1
     INTO v_ddl
    DO BEGIN
       EXECUTE STATEMENT :v_ddl;
    END

  FOR
    SELECT ddl
     FROM Lib$Cmp_ExtractProcedure('LIB$CMP_PRIVILEGES', 0)
     WHERE isRevoke = 1
     INTO v_ddl
    DO BEGIN
       EXECUTE STATEMENT :v_ddl;
    END

  IF(EXISTS (SELECT * FROM RDB$USER_PRIVILEGES WHERE RDB$RELATION_NAME = 'LIB$CMP_PRIVILEGES')) THEN
    EXCEPTION LIB$CMP_Exception 'Revoke ddl execution filed.';

  EXECUTE STATEMENT (SELECT ddl FROM Lib$Cmp_ExtractProcedure('LIB$CMP_PRIVILEGES', 0) WHERE isDrop = 1);

  IF(EXISTS (SELECT * FROM RDB$PROCEDURES WHERE RDB$PROCEDURE_NAME = 'LIB$CMP_PRIVILEGES')) THEN
    EXCEPTION LIB$CMP_Exception 'Drop ddl execution failed.';
END
^
SET TERM ;^
ROLLBACK;
