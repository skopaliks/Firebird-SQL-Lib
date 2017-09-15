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
******************************************************************************/

-- because create or alter domain doesn't exist
SET TERM ^;
EXECUTE BLOCK AS
DECLARE ds VARCHAR(500);
BEGIN
-- Domain for UTC timestamps
  ds = 'Create Domain Lib$TimestampUTC As Timestamp;';
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
END
^
SET TERM ;^
 