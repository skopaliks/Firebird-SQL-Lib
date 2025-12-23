/******************************************************************************
* Global Temporary Table : LIB$DDL_TempTable
*
* Date    : 2025-12-18
* Author  : Slavomir Skopalik
* Server  : Firebird 5.0.3
* Purpose : To work with set of commands
*
* Revision History
* ================
******************************************************************************/

CREATE GLOBAL TEMPORARY TABLE LIB$DDL_TempTable(
  id INTEGER NOT NULL,
  SQL LIB$LargeText,
  Note VARCHAR(512)
) ON COMMIT PRESERVE ROWS;

