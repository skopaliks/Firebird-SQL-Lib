:: Create update script that will update target replication cluster according master DB
:: %1 - Output script file
:: %DATABASE%        - master database
:: %DATABASE_TARGET% - Current replica member or backup of this

:: Construct SQL file

@for %%a in (%DATABASE%) do @(
  @set incsql=%TEMP%\repl_%%~na.txt
)

PUSHD .
CD /D %~dp0
DEL %1
:: Complete SQL code
@ECHO --Create DB diff for replication cluster>%incsql%
@ECHO SELECT RDB$SET_CONTEXT('USER_SESSION','DB_Target', '%DATABASE_TARGET%') FROM RDB$DATABASE; >>%incsql%
@ECHO SELECT RDB$SET_CONTEXT('USER_SESSION','usr', '%ISC_USER%') FROM RDB$DATABASE; >>%incsql%
@ECHO SELECT RDB$SET_CONTEXT('USER_SESSION','psw', '%ISC_PASSWORD%') FROM RDB$DATABASE; >>%incsql%
@ECHO SET ECHO OFF; >>%incsql%
@ECHO SET HEADING OFF; >>%incsql%
@ECHO output %1; >>%incsql%
copy /A /Y %incsql% + CmpAndUpg.sql %incsql%
IF %ERRORLEVEL% NEQ 0 goto :L_error

:: Execute SQL
%ISQL% -b -e -q -charset UTF8 -i %incsql% %DATABASE%
IF %ERRORLEVEL% NEQ 0 goto :L_error 

@ECHO 'SUCCESS - Common MASA database built'
@SET result=0
@GOTO :end

:L_error
@SET result=%ERRORLEVEL%
:: Set red foreground color
@COLOR 0C
@ECHO 'FAILED - Common MASA database' 

:end
POPD
@EXIT /B %result%

