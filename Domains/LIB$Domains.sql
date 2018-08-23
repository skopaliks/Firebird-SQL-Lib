/******************************************************************************
*         : General domain types
*
* Date    : 2017-09-07
* Author  : Slavomir Skopalik
* Server  : FB 2.5
* Purpose : Domain types for general usage
*
* Revision History
* 2017-09-15 - S.Skopalik: LIB$LargeText added
* 2018-08-23 - S.Skopalik: LIB$UUID added for storing UUID
******************************************************************************/

-- because create or alter domain doesn't exist
SET TERM ^;
EXECUTE BLOCK AS
DECLARE ds VARCHAR(500);
BEGIN
-- CRLF constant
-- use this way: DECLARE CRLF      LIB$CRLF;
-- In code like: DDL = DDL||CRLF; 
  ds = 'CREATE DOMAIN LIB$CRLF AS CHAR(2) DEFAULT x''0D0A''';
  BEGIN
    EXECUTE STATEMENT ds;
  WHEN ANY DO BEGIN END
  END  
-- Domain for UTC timestamps
  ds = 'CREATE DOMAIN Lib$TimestampUTC As Timestamp;';
  BEGIN
    EXECUTE STATEMENT ds;
  WHEN ANY DO BEGIN END
  END
-- Domain for larger UTF8 texts (like SQL DDL)
  ds = 'CREATE DOMAIN LIB$LargeText AS BLOB sub_type 1 segment size 2048 CHARACTER SET UTF8;';
  BEGIN
    EXECUTE STATEMENT ds;
  WHEN ANY DO BEGIN END
  END
-- Lib$BooleanF for FB2.5 boolean fields
  ds = 'Create Domain LIB$BooleanF As Smallint Default 0 Check (value BETWEEN 0 AND 1);';
  BEGIN
    EXECUTE STATEMENT ds;
  WHEN ANY DO BEGIN END
  END
  ds = 'CREATE DOMAIN LIB$UUID AS CHAR(16) CHARACTER SET OCTETS';
  BEGIN
    EXECUTE STATEMENT ds;
  WHEN ANY DO BEGIN END
  END
END
^
SET TERM ;^
 