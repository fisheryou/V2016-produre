cls

@echo off


:begin
set /p var_db=���������ݿ������ʵ��:

if "%var_db%"=="" goto begin

cysql32 -T -Usims2016 -PSims_2016 -S%var_db% ..\init_tables\*.sql

pause
