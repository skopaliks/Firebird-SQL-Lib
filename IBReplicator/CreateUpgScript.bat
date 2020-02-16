:: Create update script that will update target replication cluster according master DB
:: %1 - Output script file
:: %DATABASE%        - master database
:: %DATABASE_TARGET% - Current replica member or backup of this

:: Construct SQL file

@for %%a in (%DATABASE%) do @(
  @set incsql=%TEMP%\repl_%%~na.sql    
)


:: Execute SQL