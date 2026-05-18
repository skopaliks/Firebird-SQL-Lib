SET TERM ^;
EXECUTE BLOCK 
AS
DECLARE s_in LIB$LargeText;
DECLARE s LIB$LargeText;
DECLARE i INTEGER;
BEGIN
  FOR SELECT result FROM LIB$Tokenize(NULL, 'A') INTO s DO EXCEPTION LIB$QA_Fail 'NULL parsing error';
  FOR SELECT result FROM LIB$Tokenize('ABC', ',') INTO s DO BEGIN
    IF(s IS DISTINCT FROM 'ABC') THEN EXCEPTION LIB$QA_Fail 'Single term parsing error';
  END
  i = 1;
  FOR SELECT result FROM LIB$Tokenize(',ABC', ',') INTO s DO BEGIN
    IF( i = 1 AND s IS DISTINCT FROM '') THEN EXCEPTION LIB$QA_Fail 'Empty string at begining';
    IF( i = 2 AND s IS DISTINCT FROM 'ABC') THEN EXCEPTION LIB$QA_Fail 'ABC term parsing error';
    i = i + 1;
  END
  i = 1;
  FOR SELECT result FROM LIB$Tokenize('ABC,CDE', ',') INTO s DO BEGIN
    IF( i = 1 AND s IS DISTINCT FROM 'ABC') THEN EXCEPTION LIB$QA_Fail 'ABC term parsing error';
    IF( i = 2 AND s IS DISTINCT FROM 'CDE') THEN EXCEPTION LIB$QA_Fail 'CDE term parsing error';
    i = i + 1;
  END
  i = 1;
  FOR SELECT result FROM LIB$Tokenize('ABC,CDE,', ',') INTO s DO BEGIN
    IF( i = 1 AND s IS DISTINCT FROM 'ABC') THEN EXCEPTION LIB$QA_Fail 'ABC term parsing error';
    IF( i = 2 AND s IS DISTINCT FROM 'CDE') THEN EXCEPTION LIB$QA_Fail 'CDE term parsing error';
    IF( i = 3) THEN EXCEPTION LIB$QA_Fail 'NULL parsing error';
    i = i + 1;
  END
END
^
SET TERM ;^

