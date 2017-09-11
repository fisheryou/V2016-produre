USE sims2016Proc
go

IF EXISTS(SELECT 1 FROM sysobjects WHERE name = 'opClearSettleFileTmpTables')
  DROP PROC opClearSettleFileTmpTables
go

CREATE PROC opClearSettleFileTmpTables 
AS
  SET NOCOUNT ON
  DECLARE @errorcode INT, @errormsg VARCHAR(255)

  --SELECT * FROM sims2016DataExchg.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE 'sh%Tmp'
  --SELECT * FROM sims2016DataExchg.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE 'sz%Tmp'

  TRUNCATE TABLE sims2016DataExchg.dbo.shagJsmxbTmp
  TRUNCATE TABLE sims2016DataExchg.dbo.shagYwhbbTmp
  TRUNCATE TABLE sims2016DataExchg.dbo.shagZjbdbTmp
  TRUNCATE TABLE sims2016DataExchg.dbo.shagZjhzbTmp
  TRUNCATE TABLE sims2016DataExchg.dbo.shagZqbdbTmp
  TRUNCATE TABLE sims2016DataExchg.dbo.shagZqyebTmp

  TRUNCATE TABLE sims2016DataExchg.dbo.szagSjsdzbTmp
  TRUNCATE TABLE sims2016DataExchg.dbo.szagSjsfxbTmp
  TRUNCATE TABLE sims2016DataExchg.dbo.szagSjsjgbTmp
  TRUNCATE TABLE sims2016DataExchg.dbo.szagSjsmx0Tmp
  TRUNCATE TABLE sims2016DataExchg.dbo.szagSjsmx1Tmp
  TRUNCATE TABLE sims2016DataExchg.dbo.szagSjsmx2Tmp
  TRUNCATE TABLE sims2016DataExchg.dbo.szagSjsqsbTmp
  TRUNCATE TABLE sims2016DataExchg.dbo.szagSjstjbTmp
  TRUNCATE TABLE sims2016DataExchg.dbo.szagSjszjbTmp

  SELECT errorcode = 0, errormsg = '交易所有关temp表清理成功!'

  RETURN 0
go
