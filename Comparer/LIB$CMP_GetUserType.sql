/******************************************************************************
* Stored Procedure : LIB$CMP_GetUserType
*                                                                            
* Date    : 2017-09-13
* Author  : Slavomir Skopalik
* Server  : Firebird 2.5.7
* Purpose : Returns name of object for given user type number
*                                                                               
* Revision History                                                           
* ================                                                           
*                                                                            
*
* 2018/08/14 Jaroslav Kejnar - added usertype 0
******************************************************************************/
SET TERM ^;

CREATE OR ALTER PROCEDURE LIB$CMP_GetUserType(
  RDB$USER_TYPE TYPE OF COLUMN RDB$USER_PRIVILEGES.RDB$USER_TYPE NOT NULL
)RETURNS(
  UserType VARCHAR(63)
)
AS
BEGIN
  UserType =
    TRIM(CASE RDB$USER_TYPE
      WHEN 0 THEN 'TABLE'
      WHEN 2 THEN 'TRIGGER'
      WHEN 5 THEN 'PROCEDURE'
      WHEN 8 THEN 'USER'
      WHEN 13 THEN 'ROLE'
    END);
  IF(UserType IS NULL)THEN EXCEPTION LIB$CMP_Exception 'RDB$USER_TYPE('||RDB$USER_TYPE||') is unknow'; 
  SUSPEND;  
END
^

SET TERM ;^
