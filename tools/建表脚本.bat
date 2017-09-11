cls

@echo off


:begin
set /p var_db=请输入数据库服务器实例:

if "%var_db%"=="" goto begin

cysql32 -T -Usims2016system -Psims2016system -S%var_db% ..\tables\*.sql

pause
