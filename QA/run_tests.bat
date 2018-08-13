:: Create test DB run all test and drop

:: What expected:
:: %ISQL% - isql.exe
:: ISC_USER
:: ISC_PASSWORD

:: if all test success, exit code is zero otherwise non zero

@IF NOT DEFINED ISC_USER SET ISC_USER=sysdba
@IF NOT DEFINED ISC_PASSWORD SET ISC_PASSWORD=masterkey
@IF NOT DEFINED ISQL SET ISQL=c:\fb\bin\isql.exe

@PUSHD .
CD /D %~dp0

SET DATABASE=Firebird-SQL-Lib-Test.fdb
IF EXIST D:\fbdata SET DATABASE=D:\fbdata\%DATABASE%

:: Try to drop a existing database
%ISQL% -i Drop_Test_DB.sql %DATABASE%

:: Create DB and add all DB objects
SET cfile=%temp%\Firebird-SQL-Lib-Test-Create.sql

ECHO SET SQL DIALECT 3;>%cfile%
ECHO CREATE DATABASE '%DATABASE%' PAGE_SIZE 16384 DEFAULT CHARACTER SET UTF8; >>%cfile%

%ISQL% -b -e -charset UTF8 -i %cfile%
@IF %ERRORLEVEL% NEQ 0 goto :end

DEL %cfile%
@IF %ERRORLEVEL% NEQ 0 goto :end

%ISQL% -b -e -q -i Create_Test_DB.sql %DATABASE% >create.log
@IF %ERRORLEVEL% NEQ 0 goto :end

CALL ..\AddToDB.bat %DATABASE%

%ISQL% -b -e -i Test_Repl$DDL.sql %DATABASE%
@IF %ERRORLEVEL% NEQ 0 goto :end

%ISQL% -i Drop_Test_DB.sql %DATABASE%
@IF %ERRORLEVEL% NEQ 0 goto :end

:end

@POPD
