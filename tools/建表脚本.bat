cls

@echo off


:begin
set /p var_db=���������ݿ������ʵ��:

if "%var_db%"=="" goto begin

cysql32 -T -Usims2016system -Psims2016system -S%var_db% ..\tables\*.sql

pause
