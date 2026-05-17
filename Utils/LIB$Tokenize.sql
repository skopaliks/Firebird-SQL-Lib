/******************************************************************************
* Stored Procedure : LIB$DDL_ChangeDataType
*
* Date    : 2026-05-17
* Author  : Slavomir Skopalik
* Server  : Firebird 5.0.4
* Purpose : Split long text into tokens
* base on https://www.tabsoverspaces.com/232347-tokenize-string-in-sql-firebird-syntax
* 
* Revision History
* ================
******************************************************************************/

CREATE OR ALTER PROCEDURE LIB$Tokenize(Input LIB$LargeText, Token CHAR(1))
RETURNS(result LIB$LargeText)
AS
DECLARE newpos INT = 1;
DECLARE oldpos INT = 1;
BEGIN
  WHILE (TRUE) DO BEGIN
    newpos = POSITION(Token, Input, oldpos);
    IF(newpos > 0) THEN BEGIN
      result = SUBSTRING(Input FROM oldpos FOR newpos - oldpos);
      SUSPEND;
      oldpos = newpos + 1;
    END
    ELSE BEGIN 
      IF (oldpos - 1 < CHAR_LENGTH(Input)) THEN BEGIN
        result = SUBSTRING(Input FROM oldpos);
        SUSPEND;
      END
      BREAK;
    END
  END
END
