-- Include all sql files

-- General
INPUT Domains\LIB$Domains.sql;
-- Best practies
INPUT DB_Checks\LIB$CheckTriggersPossitions.sql;
COMMIT;
-- Monitoring
INPUT Utils\LIB$TR_Monitor.sql;
COMMIT;
-- DDL
INPUT DDL\LIB$DDL_Exception.sql;
INPUT DDL\LIB$DDL_DropUnq.sql;
INPUT DDL\LIB$DDL_Get_FK_Info.sql;
-- IBReplicator
INPUT IBReplicator\REPL$DBConnect.sql;
INPUT IBReplicator\REPL$DDL.sql;
-- DB compare
INPUT Comparer\LIB$CMP_Exception.sql;
INPUT Comparer\LIB$CMP_GetUserType.sql;
INPUT Comparer\LIB$CMP_GetFieldDataType.sql;
INPUT Comparer\LIB$CMP_Procedures.sql;

COMMIT;