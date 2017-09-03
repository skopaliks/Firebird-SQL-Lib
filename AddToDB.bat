:: This script add or update SQL library objects to specific DB
:: %1 - database name like localhost:d:\fbdata\db1.fdb

:: if you don't have isql.exe in PATH then set ISQL enviroment variable like c:\fb\bin\isql.exe

:: for user name and password is used ISC_USER and ISC_PASSWORD enviroment variables

IF NOT DEFINED ISQL SET ISQL=isql.exe

@PUSHD .
@CD /D %~dp0

%ISQL% -b -e -q -charset UTF8 -i IncludeAll.sql %1

@POPD
