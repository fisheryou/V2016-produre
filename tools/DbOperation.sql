/*使用说明：
1 提交脚本
2 在"配置开始"处，配置路径
3 在"操作开始"处，执行想做的操作

删除、还原等影响现有数据库的操作已被注释
*/
use master 
go

------------------------------------------------------
if object_id(N'tempdb..#db_cfg', N'U') is not null
    drop table #db_cfg
go

create table #db_cfg
(
    id        int identity(1, 1),
    name      varchar(20),  --设备名         引用方式: @name
    file_path varchar(500), --数据库文件     引用方式: @iamge
    log_path  varchar(500), --数据库日志文件 引用方式: @log
    dump_path varchar(500), --备份文件       引用方式: @dump
)
-- mssql 数据库的长度只能是20个字符，故采用缩写的方案创建数据库名
-- 数据库用户sims2016system
-- drop database sims2016TradeToday      ;    
-- drop database sims2016TradeHist       ;
-- drop database sims2016TradeArchive    ;
-- drop database sims2016TradeOffline    ;
-- drop database sims2016QuotaToday  ;
-- drop database sims2016QuotaHist   ;
-- drop database sims2016QuotaArchive;
-- drop database sims2016QuotaOffline;
-- drop database sims2016DataExchg;
-- drop database sims2016Proc;
-- drop database sims2016ClearToday;
-- drop database sims2016ClearHist;
-- drop database sims2016ClearArchive;

--------------------------------配置开始-------------------------------
truncate table #db_cfg
insert #db_cfg
       select           'sims2016TradeToday', 
                        'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016TradeToday.mdf', 'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016TradeToday.ldf', 
                        'E:\DataCenter\MSSQL$2008THIRD\Backup\sims2016TradeToday.dump'

       union all select 'sims2016TradeHist', 
                        'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016TradeHist.mdf', 'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016TradeHist.ldf', 
                        'E:\DataCenter\MSSQL$2008THIRD\Backup\sims2016TradeHist.dump'

       union all select 'sims2016TradeArchive', 
                        'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016TradeArchive.mdf', 'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016TradeArchive.ldf', 
                        'E:\DataCenter\MSSQL$2008THIRD\Backup\sims2016TradeArchive.dump'

       union all select 'sims2016TradeOffline', 
                        'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016TradeOffline.mdf', 'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016TradeOffline.ldf', 
                        'E:\DataCenter\MSSQL$2008THIRD\Backup\sims2016TradeOffline.dump'

       union all select 'sims2016QuotaToday', 
                        'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016QuotaToday.mdf', 'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016QuotaToday.ldf', 
                        'E:\DataCenter\MSSQL$2008THIRD\Backup\sims2016QuotaToday.dump'

       union all select 'sims2016QuotaHist', 
                        'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016QuotaHist.mdf', 'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016QuotaHist.ldf', 
                        'E:\DataCenter\MSSQL$2008THIRD\Backup\sims2016QuotaHist.dump'
       
       union all select 'sims2016QuotaArchive', 
                        'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016QuotaArchive.mdf', 'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016QuotaArchive.ldf', 
                        'E:\DataCenter\MSSQL$2008THIRD\Backup\sims2016QuotaArchive.dump'
        
       union all select 'sims2016QuotaOffline', 
                        'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016QuotaOffline.mdf', 'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016QuotaOffline.ldf', 
                        'E:\DataCenter\MSSQL$2008THIRD\Backup\sims2016QuotaOffline.dump'

       union all select 'sims2016DataExchg', 
                        'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016DataExchg.mdf', 'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016DataExchg.ldf', 
                        'E:\DataCenter\MSSQL$2008THIRD\Backup\sims2016DataExchg.dump'
       
       union all select 'sims2016Proc', 
                        'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016Proc.mdf', 'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016Proc.ldf', 
                        'E:\DataCenter\MSSQL$2008THIRD\Backup\sims2016Proc.dump'
--清算库
       union all select 'sims2016ClearToday', 
                        'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016ClearToday.mdf', 'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016ClearToday.ldf', 
                        'E:\DataCenter\MSSQL$2008THIRD\Backup\sims2016ClearToday.dump'

       union all select 'sims2016ClearHist', 
                        'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016ClearHist.mdf', 'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016ClearHist.ldf', 
                        'E:\DataCenter\MSSQL$2008THIRD\Backup\sims2016ClearHist.dump'

       union all select 'sims2016ClearArchive', 
                        'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016ClearArchive.mdf', 'E:\DataCenter\MSSQL$2008THIRD\Data\sims2016ClearArchive.ldf', 
                        'E:\DataCenter\MSSQL$2008THIRD\Backup\sims2016ClearArchive.dump'                        
--select * from #db_cfg
--------------------------------配置结束-------------------------------

--------------------------------操作开始-------------------------------
/*
--创建登录用户，后面手工修改用户的密码为sims2016
create_login 'sims2016system', 'sims2016system'

--创建数据库, 数据库存在则不创建
create_db 'sims2016system' 

--创建备份设备
create_device

--删除数据库
--drop_db

--备份数据库到dump_path
backup_db_path

--从dump_path恢复数据库
--restore_db_path

--备份数据库到备份设备
backup_db_device

--从备份设备恢复数据库
--restore_db_device

--分离数据库
detach_db

--附加数据库
attach_db

--------附加操作, 一般不用, 已包含在create_db中---------
--更改数据库恢复模式
set_recovery 'simple'

--设置数据库所有者
set_owner 'sims2016system'

--*/
--------------------------------操作结束-------------------------------



------------------------------------------------------
if object_id(N'tracert_db_cfg', N'P') is not null
    drop proc tracert_db_cfg
go

create proc tracert_db_cfg
    @p_sql varchar(1024),
    @p_oper varchar(10) = 'common'--create:create database, drop:drop database
as
    declare @id int, @sql varchar(1024), @name varchar(20), 
            @image varchar(500), @log varchar(500), @dump varchar(500), @backup_device varchar(50)
    
    select @id = 0
    while 1 = 1
    begin
        --取引用参数的实际值
        select top 1 @id = id, @name = name, @image = file_path, @log = log_path, @dump = dump_path 
        from #db_cfg 
        where id > @id 
        order by id
        
        if @@rowcount = 0
            break 
        
        --替换引用参数
        select @sql = replace(@p_sql, '@name', @name)
        select @sql = replace(@sql, '@image', @image)
        select @sql = replace(@sql, '@log', @log)
        select @sql = replace(@sql, '@dump', @dump)
        
        --需要特殊处理的操作
        if @p_oper = 'create'--创建数据库，数据库已存在则不操作
        begin
             if exists(select * from sys.databases where name = @name)
                continue
        end
        else if @p_oper = 'drop'--删除数据库，数据库不存在则不操作
        begin
            if not exists(select * from sys.databases where name = @name)
                continue 
        end
        else if @p_oper = 'dump'--创建备份设备，设备已存在则先删除
        begin
            select @backup_device = @name + '_backup'
            if exists(select * from sys.backup_devices where name = @backup_device)
                exec sp_dropdevice @backup_device
        end
        
        exec (@sql) 
    end    
go

------------------------------------------------------
if object_id(N'create_login', N'P') is not null
    drop proc create_login
go

create proc create_login
    @p_login varchar(200),
	@p_login_pwd varchar(200)
as
    if not exists (select * from master..syslogins where name = @p_login)
        exec sp_addlogin @p_login, @p_login_pwd, master, NULL, 0x6B6866775F64626F0000000000000000
go

------------------------------------------------------
if object_id(N'create_db', N'P') is not null
    drop proc create_db
go

create proc create_db
    @p_login varchar(200) 
as
    --创建数据库
    declare @sql varchar(1024)
    select @sql = 
'
create database @name on
( NAME = @name_data, FILENAME = ''@image'', SIZE = 10, FILEGROWTH = 10)
log on
( NAME = @name_log, FILENAME = ''@log'', SIZE = 10, FILEGROWTH = 10)
'

    exec tracert_db_cfg @sql, 'create'
    
    --配置数据库恢复模式simple
    exec set_recovery 'simple'
    
    --设置数据库所有者sims2016system   
    exec set_owner @p_login
go

------------------------------------------------------
if object_id(N'set_recovery', N'P') is not null
    drop proc set_recovery
go

create proc set_recovery
    @p_mode varchar(200) --simple, bulk-logged, full
as
    declare @c_sql varchar(1024)
    select @c_sql = 'alter database @name set recovery ' + @p_mode
    exec tracert_db_cfg @c_sql
go

------------------------------------------------------
if object_id(N'set_owner', N'P') is not null
    drop proc set_owner
go

create proc set_owner
    @p_login varchar(200) 
as
    --设置数据库所有者sims2016system   
    declare @o_sql varchar(1024)
    select @o_sql = 'alter authorization on Database::@name to ' + @p_login
    exec tracert_db_cfg @o_sql
go

------------------------------------------------------
if object_id(N'create_device', N'P') is not null
    drop proc create_device
go

create proc create_device
as
    --添加备份设备
    declare @add_sql varchar(1024)
    select @add_sql = 'exec sp_addumpdevice ''disk'', ''@name_backup'', ''@dump'''
    exec tracert_db_cfg @add_sql, 'dump'
go

------------------------------------------------------
if object_id(N'drop_db', N'P') is not null
    drop proc drop_db
go

create proc drop_db
as
    declare @d_sql varchar(1024)
    select @d_sql = 'drop database @name'
    exec tracert_db_cfg @d_sql, 'drop'
go

------------------------------------------------------
if object_id(N'backup_db_path', N'P') is not null
    drop proc backup_db_path
go

create proc backup_db_path
as
    declare @b_sql varchar(1024)
    select @b_sql = 'backup database @name to disk = ''@dump'' with init, format'
    exec tracert_db_cfg @b_sql
go

------------------------------------------------------
if object_id(N'restore_db_path', N'P') is not null
    drop proc restore_db_path
go

create proc restore_db_path
as
    declare @re_sql varchar(1024)
    select @re_sql = 
    '
    restore database @name from disk = ''@dump'' with file = 1, replace,
    move ''@name_data'' to ''@image'',  
    move ''@name_log'' to ''@log'',  
    nounload,  stats = 10
    '
    exec tracert_db_cfg @re_sql
    
    --update sims2016TradeHist..czyb set czymm = 'k0g6d4c7baae2d27922f'
    --update sims2016TradeHist..yybb set ip = '127.0.0.1', ip_hb = '127.0.0.1'
go

------------------------------------------------------
if object_id(N'backup_db_device', N'P') is not null
    drop proc backup_db_device
go

create proc backup_db_device
as
    declare @b2d_sql varchar(1024)
    select @b2d_sql = 'backup database @name to @name_backup with init'
    exec tracert_db_cfg @b2d_sql
go

------------------------------------------------------
if object_id(N'restore_db_device', N'P') is not null
    drop proc restore_db_device
go

create proc restore_db_device
as
    declare @rfd_sql varchar(1024)
    select @rfd_sql = 'restore database @name from @name_backup with replace'
    exec tracert_db_cfg @rfd_sql
go

------------------------------------------------------
if object_id(N'detach_db', N'P') is not null
    drop proc detach_db
go

create proc detach_db
as
    declare @rfd_sql varchar(1024)
    select @rfd_sql = 'sp_detach_db @dbname = @name'
    exec tracert_db_cfg @rfd_sql
go

------------------------------------------------------
if object_id(N'attach_db', N'P') is not null
    drop proc attach_db
go

create proc attach_db
as
    declare @rfd_sql varchar(1024)
    select @rfd_sql = 
'create database @name on (filename = ''@image''), ( filename = ''@log'' ) for attach'
    
    exec tracert_db_cfg @rfd_sql
go
