/******************************************************************************
*         : General domain types
*
* Date    : 2017-09-07
* Author  : Slavomir Skopalik
* Server  : FB 2.5
* Purpose : Domain types for general usage
*
* Revision History
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
END
^
SET TERM ;^
 