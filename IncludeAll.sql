-- Include all sql files

-- General
INPUT Domains\LIB$Domains.sql;
-- Best practies
INPUT DB_Checks\LIB$CheckTriggersPossitions.sql;
COMMIT;

-- Monitoring
INPUT Utils\LIB$TR_Monitor.sql;
COMMIT;

-- Support routines
INPUT Comparer\LIB$CMP_Exception.sql;
INPUT Comparer\LIB$CMP_GetUserType.sql;
INPUT Comparer\LIB$CMP_GetFieldDataType.sql;
INPUT Comparer\LIB$CMP_GetTriggerType.sql;

-- DB Compare extractors
INPUT Comparer\LIB$CMP_ExtractProcedure.sql;
INPUT Comparer\LIB$CMP_ExtractTrigger.sql;
COMMIT;

-- DDL
INPUT DDL\LIB$DDL_ChangeDataType.sql;
INPUT DDL\LIB$DDL_Exception.sql;
INPUT DDL\LIB$DDL_DropForeignKey.sql;
INPUT DDL\LIB$DDL_DropPrimaryKey.sql;
INPUT DDL\LIB$DDL_DropUnq.sql;
INPUT DDL\LIB$DDL_Get_FK_Info.sql;
COMMIT;

-- IBReplicator
INPUT IBReplicator\REPL$DBConnect.sql;
INPUT IBReplicator\REPL$SetCurrentDBNo.sql;
INPUT IBReplicator\REPL$WaitForRound.sql;
COMMIT;
INPUT IBReplicator\REPL$DDL.sql;
COMMIT;
INPUT IBReplicator\REPL$DDL_ChangeDataType.sql;
INPUT IBReplicator\REPL$DDL_DropForeignKey.sql;
INPUT IBReplicator\REPL$DDL_DropPrimaryKey.sql;
INPUT IBReplicator\REPL$DDL_DropUnq.sql;
COMMIT;

-- DB compare
-- Objects comparer
INPUT Comparer\LIB$CMP_Domains.sql;
INPUT Comparer\LIB$CMP_Privileges.sql;
INPUT Comparer\LIB$CMP_Procedures.sql;
INPUT Comparer\LIB$CMP_Tables.sql;

COMMIT;