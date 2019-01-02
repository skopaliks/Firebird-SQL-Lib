/******************************************************************************
* Stored Procedure : LIB$CMP_Privileges
*                                                                            
* Date    : 2018-06-27
* Author  : Jaroslav Kejnar
* Server  : Firebird 2.5.8
* Purpose : Compare privileges from the current DB against a remoted one.
*                                                                               
* Revision History                                                           
* ================                                                           

******************************************************************************/

-- helper temporary table
RECREATE GLOBAL TEMPORARY TABLE LIB$CMP_i_Privileges(
  Privilege_User    RDB$User,
  Privilege_Grantor CHAR(31),
  Privilege_Object  RDB$Relation_Name,
  Privilege         RDB$Privilege,
  Grant_Option      SMALLINT,
  Field_Name        RDB$Field_Name,
  User_Type         SMALLINT,
  Object_Type       RDB$Object_Type
)ON COMMIT DELETE ROWS;

CREATE INDEX LIB$CMP_i_Privileges_indx ON LIB$CMP_i_Privileges(Privilege_User, Privilege_Grantor, Privilege_Object, Privilege, Grant_Option, Field_Name, User_Type, Object_Type);

SET TERM ^;

-- helper procedure to fill temporary table
CREATE OR ALTER PROCEDURE LIB$CMP_GetPrivileges_RemoteDB(
  Target_DB       VARCHAR(500) NOT NULL,
  Target_User     VARCHAR(63),
  Target_Password VARCHAR(63),
  Target_Role     VARCHAR(63) DEFAULT NULL,
  On_Grant     VARCHAR(31) DEFAULT NULL,
  To_Grant       VARCHAR(31) DEFAULT NULL
)
AS
DECLARE ds VARCHAR(500);
DECLARE p_user TYPE OF COLUMN RDB$User_Privileges.RDB$User;
DECLARE p_grantor TYPE OF COLUMN RDB$User_Privileges.RDB$Grantor;
DECLARE p_object TYPE OF COLUMN RDB$User_Privileges.RDB$Relation_Name;
DECLARE p_privilege TYPE OF COLUMN RDB$User_Privileges.RDB$Privilege;
DECLARE p_grant_option TYPE OF COLUMN RDB$User_Privileges.RDB$Grant_Option;
DECLARE p_field_name TYPE OF COLUMN RDB$User_Privileges.RDB$Field_Name;
DECLARE p_user_type TYPE OF COLUMN RDB$User_Privileges.RDB$User_Type;
DECLARE p_object_type TYPE OF COLUMN RDB$User_Privileges.RDB$Object_Type;
BEGIN
  DELETE FROM LIB$CMP_i_Privileges;
  ds = 'SELECT RDB$User, RDB$Grantor, RDB$Relation_Name, RDB$Privilege, COALESCE(RDB$Grant_Option, 0), RDB$Field_Name, RDB$User_Type, RDB$Object_Type FROM RDB$User_Privileges';
  IF(On_Grant IS NOT NULL OR To_Grant IS NOT NULL)THEN BEGIN
     ds = ds || ' WHERE ';
     IF(On_Grant IS NOT NULL) THEN
        ds = ds || 'RDB$Relation_Name = ''' || :On_Grant || '''';
     IF(On_Grant IS NOT NULL AND To_Grant IS NOT NULL) THEN
        ds = ds || ' OR ';
     IF(To_Grant IS NOT NULL) THEN
        ds = ds || 'RDB$User = ''' || :To_Grant || '''';
  END
  FOR
    EXECUTE STATEMENT (:ds)
    ON EXTERNAL DATA SOURCE Target_DB
            AS USER Target_User
            PASSWORD Target_Password
            ROLE Target_Role
    INTO :p_user, :p_grantor, :p_object, :p_privilege, :p_grant_option, :p_field_name, :p_user_type, :p_object_type
    DO BEGIN
        INSERT INTO LIB$CMP_i_Privileges (Privilege_User, Privilege_Grantor, Privilege_Object, Privilege, Grant_Option, Field_Name, User_Type, Object_Type)
            VALUES(:p_user, :p_grantor, :p_object, :p_privilege, :p_grant_option, :p_field_name, :p_user_type, :p_object_type);
    END
END^

CREATE OR ALTER PROCEDURE LIB$CMP_Privileges(
  Target_DB       VARCHAR(500) NOT NULL,
  Target_User     VARCHAR(63),
  Target_Password VARCHAR(63),
  Target_Role     VARCHAR(63) DEFAULT NULL,
  On_Grant        VARCHAR(31) DEFAULT NULL,
  To_Grant        VARCHAR(31) DEFAULT NULL
)
RETURNS(
  Privilege_User          TYPE OF COLUMN RDB$User_Privileges.RDB$User,
  Privilege_Grantor       TYPE OF COLUMN RDB$User_Privileges.RDB$Grantor,
  Privilege_Object        TYPE OF COLUMN RDB$User_Privileges.RDB$Relation_Name,
  Privilege               TYPE OF COLUMN RDB$User_Privileges.RDB$Privilege,
  Grant_Option            TYPE OF COLUMN RDB$User_Privileges.RDB$Grant_Option,
  Field_Name              TYPE OF COLUMN RDB$User_Privileges.RDB$Field_Name,
  User_Type               VARCHAR(63),
  Object_Type             VARCHAR(63),
  IsMissing               LIB$BooleanF,
  NotExistsInCurrentDB    LIB$BooleanF
)
AS
DECLARE ds VARCHAR(500);
DECLARE p_user_type TYPE OF COLUMN RDB$User_Privileges.RDB$User_Type;
DECLARE p_object_type TYPE OF COLUMN RDB$User_Privileges.RDB$Object_Type;
BEGIN
   EXECUTE PROCEDURE LIB$CMP_GetPrivileges_RemoteDB(Target_DB, Target_User, Target_Password, Target_Role, On_Grant, To_Grant);
   NotExistsInCurrentDB = 0;
   ds = 'SELECT RDB$User, RDB$Grantor, RDB$Relation_Name, RDB$Privilege, COALESCE(RDB$Grant_Option, 0), RDB$Field_Name, RDB$User_Type, RDB$Object_Type
            FROM RDB$User_Privileges';
   IF(On_Grant IS NOT NULL OR To_Grant IS NOT NULL)THEN BEGIN
     ds = ds || ' WHERE ';
     IF(On_Grant IS NOT NULL) THEN
        ds = ds || 'RDB$Relation_Name = ''' || :On_Grant || '''';
     IF(On_Grant IS NOT NULL AND To_Grant IS NOT NULL) THEN
        ds = ds || ' OR ';
     IF(To_Grant IS NOT NULL) THEN
        ds = ds || 'RDB$User = ''' || :To_Grant || '''';
   END
   FOR
    EXECUTE STATEMENT (:ds)
    INTO :Privilege_User, :Privilege_Grantor, :Privilege_Object, :Privilege, :Grant_Option, :Field_Name, :p_user_type, :p_object_type
    DO BEGIN
        IsMissing = 0;
        SELECT UserType FROM LIB$CMP_GetUserType(:p_user_type) INTO :User_Type;
        SELECT UserType FROM LIB$CMP_GetUserType(CAST(:p_object_type AS TYPE OF COLUMN RDB$User_Privileges.RDB$User_Type)) INTO :Object_Type;
        IF(NOT EXISTS(SELECT * FROM LIB$CMP_i_Privileges
                        WHERE Privilege_User = :Privilege_User AND
                            Privilege_Grantor = :Privilege_Grantor AND
                            Privilege_Object = :Privilege_Object AND
                            Privilege = :Privilege AND
                            Grant_Option = :Grant_Option AND
                            ((Field_Name IS NULL AND :Field_Name IS NULL) OR (Field_Name = :Field_Name)) AND
                            User_Type = : p_user_type AND
                            Object_Type = :p_object_type))THEN
            IsMissing = 1;
        SUSPEND;
    END
    IsMissing = 0;
    NotExistsInCurrentDB = 1;
   FOR
    SELECT Privilege_User, Privilege_Grantor, Privilege_Object, Privilege, COALESCE(Grant_Option, 0), Field_Name, User_Type, Object_Type
        FROM LIB$CMP_i_Privileges
    INTO :Privilege_User, :Privilege_Grantor, :Privilege_Object, :Privilege, :Grant_Option, :Field_Name, :p_user_type, :p_object_type
    DO BEGIN
        IF(NOT EXISTS(SELECT * FROM RDB$User_Privileges
                        WHERE RDB$User = :Privilege_User AND
                            RDB$Grantor = :Privilege_Grantor AND
                            RDB$Relation_Name = :Privilege_Object AND
                            RDB$Privilege = :Privilege AND
                            COALESCE(RDB$Grant_Option, 0) = :Grant_Option AND
                            ((RDB$Field_Name IS NULL AND :Field_Name IS NULL) OR (RDB$Field_Name = :Field_Name)) AND
                            RDB$User_Type = : p_user_type AND
                            RDB$Object_Type = :p_object_type))THEN
            SUSPEND;
    END
END^

COMMENT ON PARAMETER LIB$CMP_PRIVILEGES.ON_GRANT IS 'Optional parameter to get privileges granted to specific object(RDB$Relation_Name). Can be combined with parameter To_Grant'^
COMMENT ON PARAMETER LIB$CMP_PRIVILEGES.TO_GRANT IS 'Optional parameter to get privileges with specified user(RDB$User). Can be combined with parameter On_Grant'^
COMMENT ON PROCEDURE LIB$CMP_PRIVILEGES IS 'Compare privileges from the current DB against a remoted one.'^

SET TERM ;^
